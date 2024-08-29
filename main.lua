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

Handlers.add('Profile', Handlers.utils.hasMatchingTag('Action', 'Profile'), function(msg)
    if not Balances[WrappedArweave] then Balances[WrappedArweave] = {} end;
    if not Balances[WrappedArweave][msg.From] then Balances[WrappedArweave][msg.From] = 0 end;
    local balance = Balances[WrappedArweave][msg.From];
    if balance <= 0 then return end;
    local request = json.decode(msg.Data);
    local profile = {
        name = msg.name,
        image = msg.image,
        createdAt = msg.Timestamp,
        Creator = msg.From,
    };
    Profiles[msg.From] = profile;
    Utils.result(msg.From, 200, "Created "..msg.Name.." Token", "Transaction");
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
    local _Memes = FetchMIP01(Utils.toNumber(msg.Page),Utils.toNumber(msg.Size));
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