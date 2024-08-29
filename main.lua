local bint = require('.bint')(256)
local ao = require('ao')
local json = require('json');

WrappedArweave = ""; -- Process Id for wAr tokens
Module = "Pq2Zftrqut0hdisH_MC2pDOT6S4eQFoxGsFUzR6r350";
MINUTE = 60000
HOUR = MINUTE * 60;
DAY = HOUR * 24;
WEEK = DAY * 7;
MONTH = DAY * 30;
Default_Supply = "100000000000000000";
Default_Denomination = "12";
Default_Bonding = "100000000000000";
if not TokenModule then TokenModule = ""; end
if not PoolModule then PoolModule = ""; end

if not MIP_ID then MIP_ID = 0 end;
if not MemeRequest then MemeRequest = {} end;
if not Memes then Memes = {} end;
if not ProfileMemes then ProfileMemes = {} end;
if not Profiles then Profiles = {} end;
if not Engagements then Engagements = {} end;
if not Balances then Balances = {} end;
if not Liquidity then Liquidity = {} end;
if not Swaps then Swaps = {}; end
if not TotalSupply then TotalSupply = {}; end

Handlers.add('Profile', Handlers.utils.hasMatchingTag('Action', 'Profile'), function(msg)
    if not Balances[WrappedArweave] then Balances[WrappedArweave] = {} end;
    if not Balances[WrappedArweave][msg.From] then Balances[WrappedArweave][msg.From] = 0 end;
    local profile = {
        Name = msg.Name,
        Image = msg.Image,
        CreatedAt = msg.Timestamp,
        Creator = msg.From,
    };
    Profiles[msg.From] = profile;
    Utils.result(msg.From, 200, "Created Profile");
end)

Handlers.add('Meme', Handlers.utils.hasMatchingTag('Action', 'Meme'), function(msg)
    if not Balances[WrappedArweave] then Balances[WrappedArweave] = {} end;
    if not Balances[WrappedArweave][msg.From] then Balances[WrappedArweave][msg.From] = 0 end;
    local balance = Balances[WrappedArweave][msg.From];
    if balance <= 0 then return end;
    local request = json.decode(msg.Data);
    local meme = {
        Post = SIP01(msg.From, msg.Timestamp, request.Tags, request.Content,request.Kind),
        AmountA = msg.AmountA,
        AmountB = msg.AmountB,
        Module = Module,
        isPump = true,
        IsActive = false,
        createdAt = msg.Timestamp,
        Creator = msg.From,
    };
    table.insert(MemeRequest, meme)
    ao.spawn(Module, {})
    Utils.result(msg.From, 200, "Created "..msg.Name.." Token", "Transaction");
end)

Handlers.add('Spawned', Handlers.utils.hasMatchingTag('Action', 'Spawned'), function(msg)
    assert(msg.From == ao.id, "Not Authorized");
    local request = table.remove(MemeRequest, 1);
    request.Pool = msg.Process;
    request.Denomination = Default_Denomination;
    request.Supply = Default_Supply;
    request.BondingCurve = Default_Bonding;
    request.Holders = {};
    request.TokenB = WrappedArweave;
    Memes[msg.Process] = request;
    if not Profiles[request.Creator] then Profiles[request.Creator] = {} end;
    table.insert(Profiles[request.Creator], msg.Process)    ;
    ao.send({
        Target = msg.Process,
        Action = "Eval",
        Data = PoolModule,
    });
end)

Handlers.add('Request', Handlers.utils.hasMatchingTag('Action', 'Request'), function(msg)
    local meme = Memes[msg.From];
    ao.send({
        Target = meme.TokenB,
        Action = "Transfer",
        Recipient = meme.Pool,
        Quantity = meme.AmountB,
    });
    ao.send({
        Target = meme.Pool,
        Action = "Init",
        Data = TokenModule,
        Meme = json.encode(meme)
    });
end)

Handlers.add('Activate', Handlers.utils.hasMatchingTag('Action', 'Activate'), function(msg)
    local meme = Memes[msg.From];
    meme.IsActive = true;
    meme.TokenA = msg.TokenA;
    meme.Holders = {}
    Memes[msg.From] = meme;
    TotalSupply[msg.TokenA] = 0;
    Liquidity[msg.From] = 0;
end)

Handlers.add('Swap', Handlers.utils.hasMatchingTag('Action', 'Swap'), function(msg)
    local swap = json.decode(msg.Swap)
    if not Swaps[msg.From] then Swaps[msg.From] = {}; end;
    if not Liquidity[msg.From] then Liquidity[msg.From] = ""; end;
    table.insert(Swaps[msg.From], swap);
    Liquidity[msg.From] = msg.Liquidity;
    local _pool = Memes[msg.From];
    if not _pool.TokenA then _pool.TokenA = msg.TokenA; end;
    ao.send({
        Target = _pool.TokenA,
        Action = 'Total-Supply',
    })
    ao.send({
        Target = _pool.TokenA,
        Action = 'Holders',
    })
end)

Handlers.add('Swaps', Handlers.utils.hasMatchingTag('Action', 'Swaps'), function(msg)
    if not Swaps[msg.Pool] then
        Utils.result(msg.from, 200, {})
        return;
    end;
    Utils.result(msg.from, 200, Swaps[msg.Pool]);
end)

Handlers.add('totalSupply', Handlers.utils.hasMatchingTag('Action', 'Total-Supply'), function(msg)
    assert(msg.From ~= ao.id, 'Cannot call Total-Supply from the same process!')
    TotalSupply[msg.From] = msg.Data;
end)

Handlers.add('Holders', Handlers.utils.hasMatchingTag('Action', 'Holders'), function(msg)
    assert(msg.From ~= ao.id, 'Cannot call Holders from the same process!')
    local _balances = json.decode(msg.Data);
    local count = 0;
    local top10 = 0;
    local dev = 0;
    local meme = Memes[msg.Meme];
    for k, v in Spairs(_balances, function(t, a, b) return t[b] < t[a] end) do
        if k == msg.Minter then
            dev = Utils.toNumber(v) / Utils.toNumber(msg.Supply);
        end;
        if count < 10 and k ~= meme.Pool then
            top10 = top10 + v;
        end;
        count = count + 1;
    end;
    local holders = {
        count = count,
        top10 = Utils.toNumber(top10) / Utils.toNumber(msg.Supply),
        dev = dev
    };
    meme.Holders = holders;
    Memes[msg.Meme] = meme;
end)

Handlers.add('FetchMemes', Handlers.utils.hasMatchingTag('Action', 'FetchMemes'), function(msg)
    local _Memes = Fetch(Memes,Utils.toNumber(msg.Page),Utils.toNumber(msg.Size));
    local Results = {};
    for k, v in pairs(_Memes) do
        v.analytics = AnalyticsData(v.Pool, msg.Timestamp);
        v.Engagement = {};
        table.insert(Results, v);
    end;
    ao.send({
        Target = msg.From,
        Data = json.encode(Results)
    });
end)

Handlers.add('FetchProfileMemes', Handlers.utils.hasMatchingTag('Action', 'FetchProfileMemes'), function(msg)
    local _Memes = json.decode(msg.Memes);
    local Results = {};
    for i, v in ipairs(_Memes) do
        if Memes[i] ~= nil then
            local meme = Memes[i]
            meme.analytics = AnalyticsData(meme.Pool, msg.Timestamp);
            meme.Engagement = {};
            table.insert(Results, meme);
        end
    end;
    ao.send({
        Target = msg.From,
        Data = json.encode(Results)
    });
end)

Handlers.add('FetchProfiles', Handlers.utils.hasMatchingTag('Action', 'FetchProfiles'), function(msg)
    local _Profiles = Fetch(Profiles,Utils.toNumber(msg.Page),Utils.toNumber(msg.Size));
    ao.send({
        Target = msg.From,
        Data = json.encode(_Profiles)
    });
end)

Handlers.add('getProfile', Handlers.utils.hasMatchingTag('Action', 'getProfile'), function(msg)
    if Profiles[msg.Profile] == nil then return end
    ao.send({
        Target = msg.From,
        Data = json.encode(Profiles[msg.Profile])
    });
end)


Handlers.add('GetMeme', Handlers.utils.hasMatchingTag('Action', 'GetMeme'), function(msg)
    local meme = Memes[msg.PoolId];
    meme.analytics = AnalyticsData(msg.PoolId, msg.Timestamp);
    meme.Engagement = {};
    ao.send({
        Target = msg.From,
        Data = json.encode(meme)
    });
end)

Handlers.add('Bonded', Handlers.utils.hasMatchingTag('Action', 'Bonded'), function(msg)
    if not Memes[msg.From] then return; end
    local meme = Memes[msg.From];
    meme.isPump = false;
    Memes[msg.From] = meme;
end)

Handlers.add("Credit-Notice", Handlers.utils.hasMatchingTag('Action', "Credit-Notice"), function(msg)
    CreditNotice(msg)
end);

Handlers.add('TokenModule', Handlers.utils.hasMatchingTag('Action', 'TokenModule'), function(msg)
    TokenModule = msg.Data;
    Utils.result(msg.From, 200, msg.Data);
end)

Handlers.add('PoolModule', Handlers.utils.hasMatchingTag('Action', 'PoolModule'), function(msg)
    PoolModule = msg.Data;
    Utils.result(msg.From, 200, msg.Data);
end)

Utils = {
    add = function(a, b)
        return tostring(bint(a) + bint(b))
    end,
    subtract = function(a, b)
        return tostring(bint(a) - bint(b))
    end,
    mul = function(a, b)
        return tostring(bint.__mul(a, b))
    end,
    div = function(a, b)
        return tostring(bint.tdiv(tonumber(a), tonumber(b)))
    end,
    toBalanceValue = function(a)
        return tostring(bint(a))
    end,
    toNumber = function(a)
        return tonumber(a)
    end,
    result = function(target, code, description, label)
        ao.send({
            Target = target,
            Data = json.encode({ code = code, label = label, description = description })
        });
    end
}

function CreditNotice(msg)
    if not Balances[msg.From] then Balances[msg.From] = {} end;
    if not Balances[msg.From][msg.Sender] then Balances[msg.From][msg.Sender] = 0 end;
    local balance = Balances[msg.From][msg.Sender];
    Balances[msg.From][msg.Sender] = Utils.toNumber(balance) + Utils.toNumber(msg.Quantity);
end

function AnalyticsData(pool, timestamp)
    local price = 0;
    local supply = Utils.toNumber(TotalSupply[Memes[pool].TokenA]);
    local volume = "0";
    local _buys = "0";
    local hourVolume = {
        now = "0",
        past = "0",
    };

    local dailyVolume = {
        now = "0",
        past = "0",
    };

    local weeklyVolume = {
        now = "0",
        past = "0",
    };

    local montlyVolume = {
        now = "0",
        past = "0",
    };
    if next(Swaps) ~= nil then
        local _swaps = Swaps[pool];
        if not _swaps then else
            for _, v in ipairs(_swaps) do
                if v.isBuy then
                    _buys = _buys + 1;
                end
            end
            price = Utils.toNumber(_swaps[1].tokenB) / Utils.toNumber(_swaps[1].tokenA);
            volume = Volume(pool);
            hourVolume = {
                now = HourVolume(pool, timestamp),
                past = HourVolume(pool, Utils.toBalanceValue(Utils.toNumber(timestamp) - HOUR)),
            };

            dailyVolume = {
                now = DailyVolume(pool, timestamp),
                past = DailyVolume(pool, Utils.toBalanceValue(Utils.toNumber(timestamp) - DAY)),
            };

            weeklyVolume = {
                now = WeeklyVolume(pool, timestamp),
                past = WeeklyVolume(pool, Utils.toBalanceValue(Utils.toNumber(timestamp) - WEEK)),
            };

            montlyVolume = {
                now = MonthlyVolume(pool, timestamp),
                past = MonthlyVolume(pool, Utils.toBalanceValue(Utils.toNumber(timestamp) - MONTH)),
            };
        end
    end

    local marketCap = math.floor(supply * price);
    local data = {
        liquidty = tostring(math.floor(Liquidity[pool])),
        volume = tostring(math.floor(Utils.toNumber(volume))),
        hourVolume = hourVolume,
        dayVolume = dailyVolume,
        weekVolume = weeklyVolume,
        montlyVolume = montlyVolume,
        marketCap = marketCap,
        price = tostring(price),
        buys = _buys
    };

    return data
end

function Volume(pool)
    local _volume = "0";
    local _swaps = Swaps[pool];
    for k, v in pairs(_swaps) do
        _volume = _volume + v.tokenB
    end;
    return _volume;
end

function HourVolume(pool, timestamp)
    local _volume = "0";
    local start = Utils.toNumber(Utils.subtract(timestamp, Utils.toBalanceValue(HOUR)));
    local stop = Utils.toNumber(timestamp);
    local _swaps = Swaps[pool];
    for k, v in pairs(_swaps) do
        if Utils.toNumber(v.timestamp) <= stop and Utils.toNumber(v.timestamp) >= start then
            _volume = Utils.add(_volume, v.tokenB)
        end
    end
    return _volume;
end

function DailyVolume(pool, timestamp)
    local _volume = "0";
    local start = Utils.toNumber(Utils.subtract(timestamp, Utils.toBalanceValue(DAY)));
    local stop = Utils.toNumber(timestamp);
    local _swaps = Swaps[pool];
    for k, v in pairs(_swaps) do
        if Utils.toNumber(v.timestamp) <= stop and Utils.toNumber(v.timestamp) >= start then
            _volume = Utils.add(_volume, v.tokenB)
        end
    end
    return _volume;
end

function WeeklyVolume(pool, timestamp)
    local _volume = "0";
    local start = Utils.toNumber(Utils.subtract(timestamp, Utils.toBalanceValue(WEEK)));
    local stop = Utils.toNumber(timestamp);
    local _swaps = Swaps[pool];
    for k, v in pairs(_swaps) do
        if Utils.toNumber(v.timestamp) <= stop and Utils.toNumber(v.timestamp) >= start then
            _volume = Utils.add(_volume, v.tokenB)
        end
    end
    return _volume;
end

function MonthlyVolume(pool, timestamp)
    local _volume = "0";
    local start = Utils.toNumber(Utils.subtract(timestamp, Utils.toBalanceValue(MONTH)));
    local stop = Utils.toNumber(timestamp);
    local _swaps = Swaps[pool];
    for k, v in pairs(_swaps) do
        if Utils.toNumber(v.timestamp) <= stop and Utils.toNumber(v.timestamp) >= start then
            _volume = Utils.add(_volume, v.tokenB)
        end
    end
    return _volume;
end

function Spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a, b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function Fetch(tbl,page,size)
    local tempArray = {}
    local index = 1
    for k, v in pairs(tbl) do
        tempArray[index] = { k, v }
        index = index + 1
    end
    local start = (page - 1) * size + 1
    local endPage = page * size
    local result = {};
    for i = start, endPage do
        if tempArray[i] then
            table.insert(result,tempArray[i])
        else
            break
        end
    end
    return result[1];
end