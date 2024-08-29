local bint = require('.bint')(256)
local ao = require('ao')
local json = require('json');

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
