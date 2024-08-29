local bint = require('.bint')(256)
local ao = require('ao')
local json = require('json');


--Pool/Token
--[[{
    Pool = "",
    Minter = msg.From,
    Name = msg.Name,
    Ticker = msg.Ticker,
    Logo = msg.Logo,
    Description = msg.Description,
    Denomination = Default_Denomination,
    Supply = Default_Supply,
    Holders = {},
    TokenB = msg.TokenB,
    BondingCurve = Default_Bonding,
    AmountA = msg.AmountA,
    AmountB = msg.AmountB,
    Module = Module,
    isPump = true,
    IsActive = false,
    createdAt = msg.Timestamp
    Analytics = {}
};]]--

if not MIP_ID then MIP_ID = 0 end;
if not Memes then Memes = {} end;

Handlers.add('Post', Handlers.utils.hasMatchingTag('Action', 'Post'), function(msg)
    --[[local postRequest{
        Kind = Number,
        Tags = [strings of processIds],
        Content = <arbitrary stringified JSON object or string depending on kind>
    }]]--
    
    local postRequest = Json.decode(msg.PostRequest)

    ao.send({
        Target = _pool.TokenA,
        Action = 'Total-Supply',
    })
    ao.send({
        Target = _pool.TokenA,
        Action = 'Holders',
    })
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

function spairs(t, order)
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
