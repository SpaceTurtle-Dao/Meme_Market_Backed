local bint = require('.bint')(256)
local ao = require('ao')
local json = require('json');

WrappedArweave = "WPyLgOqELOyN_BoTNdeEMZp5sz3RxDL19IGcs3A9IPc"; -- change to before launch Process Id for wAr tokens
Module = "Pq2Zftrqut0hdisH_MC2pDOT6S4eQFoxGsFUzR6r350";
MINUTE = 60000
HOUR = MINUTE * 60;
DAY = HOUR * 24;
WEEK = DAY * 7;
MONTH = DAY * 30;
Default_Supply = "1000000000000000000000";
Default_Denomination = "12";
Default_Bonding = "100000000000000";
if not TokenModule then TokenModule = ""; end
if not PoolModule then PoolModule = ""; end

if not MIP_ID then MIP_ID = 0 end;
if not MemeRequest then MemeRequest = {} end;
if not Memes then Memes = {} end;
if not Replies then Replies = {} end;
if not Pumps then Pumps = {} end;
if not ProfileMemes then ProfileMemes = {} end;
if not Profiles then Profiles = {} end;
if not Balances then Balances = {} end;
if not Liquidity then Liquidity = {} end;
if not Swaps then Swaps = {}; end
if not TotalSupply then TotalSupply = {}; end

--[[MemeRequest = {}
ProfileMemes = {}
Profiles = {}
Memes = {}
Replies = {}
MIP_ID = 0]]--

Handlers.add('Spawned', Handlers.utils.hasMatchingTag('Action', 'Spawned'), function(msg)
    assert(msg.From == ao.id, "Not Authorized");
    local request = table.remove(MemeRequest, 1);
    request.Pool = msg.Process;
    request.Denomination = Default_Denomination;
    request.Supply = Default_Supply;
    request.BondingCurve = Default_Bonding;
    request.Holders = {};
    request.TokenB = WrappedArweave;
    request.Analytics = {};
    request.Replies = 0;
    request.Pumps = 0;
    request.Dumps = 0;
    Memes[msg.Process] = request;
    if not ProfileMemes[request.Creator] then ProfileMemes[request.Creator] = {} end;
    table.insert(ProfileMemes[request.Creator], msg.Process);
    ao.send({
        Target = msg.Process,
        Action = "Eval",
        Data = PoolModule,
    });
end)

Handlers.add('Request', Handlers.utils.hasMatchingTag('Action', 'Request'), function(msg)
    local meme = Memes[msg.From];
    ao.send({
        Target = WrappedArweave,
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
    TotalSupply[msg.TokenA] = 0;
    Liquidity[msg.From] = 0;
    if meme.Post.Parent and Memes[meme.Post.Parent] then
        Reply(meme.Pool,meme.Post.Parent);
        local parent = Memes[meme.Post.Parent]
        parent.Replies = parent.Replies + 1
        Memes[meme.Post.Parent] = parent;
    else
        meme.Post.Parent = nil
    end
    Memes[msg.From] = meme;
end)

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

Handlers.add('Swap', Handlers.utils.hasMatchingTag('Action', 'Swap'), function(msg)
    if not Memes[msg.From] then return end;
    local swap = json.decode(msg.Swap)
    local meme = Memes[msg.From];
    if not Swaps[msg.From] then Swaps[msg.From] = {}; end;
    if not Liquidity[msg.From] then Liquidity[msg.From] = ""; end;
    table.insert(Swaps[msg.From], swap);
    Liquidity[msg.From] = msg.Liquidity;
    if swap.IsBuy then
        meme.Pumps = meme.Pumps + 1;
    else
        meme.Dumps = meme.Dumps + 1;
    end
    Memes[msg.From] = meme;
    ao.send({
        Target = meme.TokenA,
        Action = 'Total-Supply',
    })
    ao.send({
        Target = meme.TokenA,
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
    local meme = Memes[msg.Pool];
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
    local _Memes = Fetch(Memes, Utils.toNumber(msg.Page), Utils.toNumber(msg.Size));
    local Results = {};
    for i, v in ipairs(_Memes) do
        if v.IsActive then
            v.Analytics = AnalyticsData(v.Pool, msg.Timestamp);
            v.Engagement = {};
            table.insert(Results, v); 
        end
    end;
    ao.send({
        Target = msg.From,
        Data = json.encode(_Memes)
    });
end)

Handlers.add('FetchReplies', Handlers.utils.hasMatchingTag('Action', 'FetchReplies'), function(msg)
    if not Replies[msg.Parent] then
        ao.send({
            Target = msg.From,
            Data = json.encode({})
        });
    end
    local _Replies = Fetch(Replies[msg.Parent], Utils.toNumber(msg.Page), Utils.toNumber(msg.Size));
    local Results = {};
    for i, v in ipairs(_Replies) do
        table.insert(Results, v);
    end;
    ao.send({
        Target = msg.From,
        Data = json.encode(Results)
    });
end)

Handlers.add('FetchMemesByIds', Handlers.utils.hasMatchingTag('Action', 'FetchMemesByIds'), function(msg)
    local Results = {};
    local memes = json.decode(msg.Memes)
    for i, v in ipairs(memes) do
        if Memes[v] then
            table.insert(Results, v); 
        end
    end;
    ao.send({
        Target = msg.From,
        Data = json.encode(Results)
    });
end)

Handlers.add('FetchProfileMemes', Handlers.utils.hasMatchingTag('Action', 'FetchProfileMemes'), function(msg)
    local _Memes = Fetch(Memes, Utils.toNumber(msg.Page), Utils.toNumber(msg.Size));
    local Results = {};
    for i, v in ipairs(_Memes) do
        if v.Creator == msg.Profile and v.IsActive then
            v.Analytics = AnalyticsData(v.Pool, msg.Timestamp);
            v.Engagement = {};
            table.insert(Results, v);
        end
    end;
    ao.send({
        Target = msg.From,
        Data = json.encode(Results)
    });
end)

Handlers.add('FetchProfiles', Handlers.utils.hasMatchingTag('Action', 'FetchProfiles'), function(msg)
    local _Profiles = Fetch(Profiles, Utils.toNumber(msg.Page), Utils.toNumber(msg.Size));
    ao.send({
        Target = msg.From,
        Data = json.encode(_Profiles)
    });
end)

Handlers.add('GetProfile', Handlers.utils.hasMatchingTag('Action', 'GetProfile'), function(msg)
    if Profiles[msg.Profile] == nil then return end
    ao.send({
        Target = msg.From,
        Data = json.encode(Profiles[msg.Profile])
    });
end)


Handlers.add('GetMeme', Handlers.utils.hasMatchingTag('Action', 'GetMeme'), function(msg)
    if Memes[msg.Meme] == nil then return end
    local meme = Memes[msg.Meme];
    meme.Analytics = AnalyticsData(meme.Pool, msg.Timestamp);
    meme.Engagement = {};
    ao.send({
        Target = msg.From,
        Data = json.encode(meme)
    });
end)

Handlers.add('Bonded', Handlers.utils.hasMatchingTag('Action', 'Bonded'), function(msg)
    if not Memes[msg.From] then return; end
    local meme = Memes[msg.From];
    meme.IsPump = false;
    Memes[msg.From] = meme;
end)

Handlers.add('TokenModule', Handlers.utils.hasMatchingTag('Action', 'TokenModule'), function(msg)
    TokenModule = msg.Data;
    Utils.result(msg.From, 200, msg.Data);
end)

Handlers.add('PoolModule', Handlers.utils.hasMatchingTag('Action', 'PoolModule'), function(msg)
    PoolModule = msg.Data;
    Utils.result(msg.From, 200, msg.Data);
end)

Handlers.add("Credit-Notice", Handlers.utils.hasMatchingTag('Action', "Credit-Notice"), function(msg)
    CreditNotice(msg)
end);

function CreditNotice(msg)
    if (msg.From == WrappedArweave) then
        local parent = nil;
        if msg['X-Parent'] then parent = msg['X-Parent'] end;
        local Kind = msg['X-Kind'];
        local Tags = json.decode(msg['X-Tags']);
        local Content = msg['X-Content'];
        local AmountA = msg['X-Amount'];
        local AmountB = msg.Quantity;
        Meme(msg.Sender, Kind, Tags, Content, AmountA, AmountB, msg.Timestamp, parent);
    end
end

function Meme(From, Kind, Tags, Content, AmountA, AmountB, Timestamp, Parent)
    local post = {
        Kind = Kind,
        Tags = Tags,
        Content = Content,
        Parent = Parent
    };
    local meme = {
        Post = post,
        AmountA = AmountA,
        AmountB = AmountB,
        Module = Module,
        IsPump = true,
        IsActive = false,
        createdAt = Timestamp,
        Creator = From,
    };
    table.insert(MemeRequest, meme)
    ao.spawn(Module, {})
    Utils.result(From, 200, "Created Meme", "Transaction");
end

function Reply(pool,parent)
    if not Replies[parent] then Replies[parent] = {} end;
    table.insert(Replies[parent], pool) 
end

function AnalyticsData(pool, timestamp)
    local price = 0;
    local supply = Utils.toNumber(TotalSupply[Memes[pool].TokenA]);
    local volume = "0";
    local _buys = "0";
    local hourVolume = {
        Now = "0",
        Past = "0",
    };

    local dailyVolume = {
        Now = "0",
        Past = "0",
    };

    local weeklyVolume = {
        Now = "0",
        Past = "0",
    };

    local montlyVolume = {
        Now = "0",
        Past = "0",
    };
    if next(Swaps) ~= nil then
        local _swaps = Swaps[pool];
        if not _swaps then else
            for _, v in ipairs(_swaps) do
                if v.IsBuy then
                    _buys = _buys + 1;
                end
            end
            price = Utils.toNumber(_swaps[1].TokenB) / Utils.toNumber(_swaps[1].TokenA);
            volume = Volume(pool);
            hourVolume = {
                Now = HourVolume(pool, timestamp),
                Past = HourVolume(pool, Utils.toBalanceValue(Utils.toNumber(timestamp) - HOUR)),
            };

            dailyVolume = {
                Now = DailyVolume(pool, timestamp),
                Past = DailyVolume(pool, Utils.toBalanceValue(Utils.toNumber(timestamp) - DAY)),
            };

            weeklyVolume = {
                Now = WeeklyVolume(pool, timestamp),
                Past = WeeklyVolume(pool, Utils.toBalanceValue(Utils.toNumber(timestamp) - WEEK)),
            };

            montlyVolume = {
                Now = MonthlyVolume(pool, timestamp),
                Past = MonthlyVolume(pool, Utils.toBalanceValue(Utils.toNumber(timestamp) - MONTH)),
            };
        end
    end

    local marketCap = math.floor(supply * price);
    local data = {
        Liquidty = tostring(math.floor(Liquidity[pool])),
        Volume = tostring(math.floor(Utils.toNumber(volume))),
        HourVolume = hourVolume,
        DayVolume = dailyVolume,
        WeekVolume = weeklyVolume,
        MontlyVolume = montlyVolume,
        MarketCap = marketCap,
        Price = tostring(price),
        Buys = _buys
    };

    return data
end

function Volume(pool)
    local _volume = "0";
    local _swaps = Swaps[pool];
    for k, v in pairs(_swaps) do
        _volume = _volume + v.TokenB
    end;
    return _volume;
end

function HourVolume(pool, timestamp)
    local _volume = "0";
    local start = Utils.toNumber(Utils.subtract(timestamp, Utils.toBalanceValue(HOUR)));
    local stop = Utils.toNumber(timestamp);
    local _swaps = Swaps[pool];
    for k, v in pairs(_swaps) do
        if Utils.toNumber(v.Timestamp) <= stop and Utils.toNumber(v.Timestamp) >= start then
            _volume = Utils.add(_volume, v.TokenB)
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
        if Utils.toNumber(v.Timestamp) <= stop and Utils.toNumber(v.Timestamp) >= start then
            _volume = Utils.add(_volume, v.TokenB)
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
        if Utils.toNumber(v.Timestamp) <= stop and Utils.toNumber(v.Timestamp) >= start then
            _volume = Utils.add(_volume, v.TokenB)
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
        if Utils.toNumber(v.Timestamp) <= stop and Utils.toNumber(v.Timestamp) >= start then
            _volume = Utils.add(_volume, v.TokenB)
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

function Fetch(tbl, page, size)
    local tempArray = {}
    for k, v in pairs(tbl) do
        table.insert(tempArray, v)
    end
    local start = (page - 1) * size + 1
    local endPage = page * size
    local result = {};
    for i = start, endPage do
        if tempArray[i] then
            table.insert(result, tempArray[i])
        else
            break
        end
    end
    return result;
end

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