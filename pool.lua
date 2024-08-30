local ao = require('ao');
local json = require('json');
local bint = require('.bint')(256)

if not TokenInfo then TokenInfo = {} end;
if not Shares then Shares = {} end;
if not Balances then Balances = {} end;

TotalShares = "10000000000000000000";
Precision = "100000000000000000";
FeeRate = "0.01" -- Fee rate (1% in this example)
TokenA = "";
TokenB = "";
IsPump = true;
IsActive = false;
Creator = "";
BondingCurve = "100000000000000";
TokenAProcess = "";
TokenBProcess = "";
Meme = {};
TokenModule = "";

Utils = {
    add = function(a, b)
        return tostring(bint(a) + bint(b))
    end,
    subtract = function(a, b)
        return tostring(bint.__sub(a,b))
    end,
    mul = function(a, b)
        return tostring(bint.__mul(a,b))
    end,
    div = function(a, b)
        return tostring(bint.tdiv(tonumber(a),tonumber(b)))
    end,
    toBalanceValue = function(a)
        return tostring(bint(a))
    end,
    toNumber = function(a)
        return tonumber(a)
    end,
    result = function(target, code, message)
        ao.send({
            Target = target,
            Data = json.encode({ code = code, message = message })
        });
    end
}

Handlers.add('Init', Handlers.utils.hasMatchingTag('Action', 'Init'), function(msg)
    assert(msg.From == Owner, "Not Authorized");
    assert(IsActive == false, "Pool is already active");
    Meme = json.decode(msg.Meme);
    local quantity = Utils.subtract(Meme.Supply,Meme.AmountA);
    IsPump = Meme.IsPump;
    TokenModule = msg.Data;
    TokenBProcess = Meme.TokenB;
    Creator = Meme.Creator;
    BondingCurve = Meme.BondingCurve;
    TokenA = quantity;
    TokenB = Meme.AmountB;
    ao.spawn(Meme.Module, {})
end)

Handlers.add('Spawned', Handlers.utils.hasMatchingTag('Action', 'Spawned'), function(msg)
    assert(msg.From == ao.id, "Not Authorized");
    TokenAProcess = msg.Process;
    ao.send({
        Target = msg.Process,
        Action = "Eval",
        Data = TokenModule,
    });
end)

Handlers.add('Activate', Handlers.utils.hasMatchingTag('Action', 'Activate'), function(msg)
    assert(msg.From == TokenAProcess, "Bad Request");
    IsActive = true;
    ao.send({
        Target = msg.From,
        Action = "Mint",
        Recipient = ao.id,
        Quantity = TokenA,
    });
    ao.send({
        Target = msg.From,
        Action = "Mint",
        Recipient = Creator,
        Quantity = Meme.AmountA,
    });
    ao.send({
        Target = Owner,
        Action = "Activate",
        TokenA = TokenAProcess,
    });
end)


Handlers.add("Add", Handlers.utils.hasMatchingTag('Action', "Add"), function(msg)
    Add(msg.From, msg.amountA, msg.amountB)
end);

Handlers.add("Remove", Handlers.utils.hasMatchingTag('Action', "Remove"), function(msg)
    assert(IsPump == false, "You can't remove liquidity from pumps")
    assert(IsActive, "Pool must be active")
    Remove(msg.From, msg.share)
end);

Handlers.add("SwapA", Handlers.utils.hasMatchingTag('Action', "SwapA"), function(msg)
    assert(IsActive, "Pool must be active")
    SwapA(msg.From, msg.amount, msg.slippage, msg.Timestamp);
end);

Handlers.add("SwapB", Handlers.utils.hasMatchingTag('Action', "SwapB"), function(msg)
    assert(IsActive, "Pool must be active")
    SwapB(msg.From, msg.amount, msg.slippage, msg.Timestamp);
end)

Handlers.add('Balance', Handlers.utils.hasMatchingTag('Action', 'Balance'), function(msg)
    Balance(msg)
end)

Handlers.add("Credit-Notice", Handlers.utils.hasMatchingTag('Action', "Credit-Notice"), function(msg)
    CreditNotice(msg)
end);

Handlers.add('Info', Handlers.utils.hasMatchingTag('Action', 'Info'), function(msg)
    Info(msg)
end)

function Init(tokenA, tokenB, bondingCurve, Creator)
    TokenAProcess = tokenA;
    TokenBProcess = tokenB;
    Creator = Creator;
    BondingCurve = bondingCurve;
    Balances[TokenAProcess] = {};
    Balances[TokenBProcess] = {};
    ao.spawn(Module, {})
end

--[[function InitalLiquidity(from, amountA, amountB)
    if not Shares[from] then Shares[from] = 0 end;
    _Share = 0;
    local isValidA = IsValid(from, TokenAProcess, amountA)
    local isValidB = IsValid(from, TokenBProcess, amountB)
    if (TotalShares == 0) then _Share = 100 * Precision end;
    if (isValidA == false or isValidB == false) then
        Utils.result(from, 403, "Invalid Amount")
        return
    end;
    SubstractBalance(from, TokenAProcess, amountA);
    SubstractBalance(from, TokenBProcess, amountB);
    TokenA = TokenA + amountA;
    TokenB = TokenB + amountB;
    local _share = Shares[from];
    Shares[from] = _share + _Share;
    TotalShares = TotalShares + _Share;
    IsActive = true;
end]]--

function Add(from, amountA, amountB)
    --[[if IsActive == false then
        InitalLiquidity(from, amountA, amountB);
        return
    end]]--
    if not Shares[from] then Shares[from] = 0 end;
    _Share = 0;
    local isValidA = IsValid(from, TokenAProcess, amountA)
    local isValidB = IsValid(from, TokenBProcess, amountB)
    if (TotalShares == 0) then _Share = 100 * Precision end;
    if (TokenA <= 0 or TokenB <= 0) then
        Utils.result(from, 403, "Pool as a zero balance of one or more tokens")
        return
    end;
    if (isValidA == false or isValidB == false) then
        Utils.result(from, 403, "Invalid Amount")
        return
    end;
    local estimateB = GetEquivalentTokenAEstimate(amountB);
    if amountB ~= estimateB then
        Utils.result(from, 403, "Invalid Amount")
        return
    end;
    local shareA = (TotalShares * amountA) / TokenA;
    local shareB = (TotalShares * amountB) / TokenB;
    if shareA ~= shareB then
        Utils.result(from, 403, "Invalid Shares")
        return
    end;
    _Share = shareA;
    SubstractBalance(from, TokenAProcess, amountA);
    SubstractBalance(from, TokenBProcess, amountB);
    TokenA = TokenA + amountA;
    TokenB = TokenB + amountB;
    local _share = Shares[from];
    Shares[from] = _share + _Share;
    TotalShares = TotalShares + _Share;
end

function Remove(from, share)
    if not Shares[from] then Shares[from] = 0 end;
    if TotalShares <= 0 then
        Utils.result(from, 403, "Totals Shares less then or equal to 0")
        return
    end;
    if TotalShares < share then
        Utils.result(from, 403, "Total Shares less then requested amount")
        return
    end;
    local estimate = GetRemoveEstimate(share);
    if estimate.shareA <= 0 and estimate.shareB <= 0 then
        Utils.result(from, 403, "No Shares available")
        return
    end;
    if TokenA < estimate.shareA then
        Utils.result(from, 403, "Invalid Amount in reserve A")
        return
    end;
    if TokenB < estimate.shareB then
        Utils.result(from, 403, "Invalid Amount in reserve B")
        return
    end;
    Shares[from] = _Share - share;
    AddBalance(from, TokenAProcess, estimate.shareA);
    AddBalance(from, TokenBProcess, estimate.shareB);
    TotalShares = TotalShares + share;
    ao.send({
        Target = TokenAProcess,
        Action = "transfer",
        Recipient = from,
        Quantity = estimate.shareA
    });
    ao.send({
        Target = TokenBProcess,
        Action = "transfer",
        Recipient = from,
        Quantity = estimate.shareB
    });
end

function SwapA(from, amount, slippage, timestamp)
    if Utils.toNumber(TotalShares) <= 0 and IsPump == false then
        Utils.result(from, 403, "Total Shares less then or equal to 0")
        return
    end;
    local estimate = GetSwapTokenAEstimate(amount);
    if estimate <= Utils.toNumber(slippage) then
        Utils.result(from, 403, "slippage "..estimate)
        return
    end;
    if Utils.toNumber(TokenB) <= 0 then
        Utils.result(from, 403, "No funds available "..estimate)
        return
    end;
    if Utils.toNumber(TokenB) < estimate then
        Utils.result(from, 403, "Insufficient funds available "..estimate)
        return
    end;
    local isValid = IsValid(from, TokenAProcess, amount)
    if isValid ~= true then
        Utils.result(from, 403, "Insufficient funds "..estimate)
        return
    end;
    SubstractBalance(from, TokenAProcess, amount);
    AddBalance(from, TokenBProcess, estimate);
    TokenA = TokenA + amount;
    TokenB = TokenB - Utils.toBalanceValue(estimate);
    local liquidity = GetLiquidity();
    if liquidity >= Utils.toNumber(BondingCurve) then
        IsPump = false;
        ao.send({
            Target = Owner,
            Action = "Bonded"
        });
    end
    local _swap = {
        isBuy = false,
        tokenA = tostring(estimate),
        tokenB = tostring(amount),
        timestamp = timestamp
    };
    ao.send({
        Target = Owner,
        Action = "Swap",
        Swap = json.encode(_swap),
        Liquidity = tostring(liquidity),
        TokenA = TokenAProcess
    });
end

function SwapB(from, amount, slippage, timestamp)
    if Utils.toNumber(TotalShares) <= 0 and IsPump == false then
        Utils.result(from, 403, "Total Shares less then or equal to 0")
        return
    end;
    local estimate = GetSwapTokenBEstimate(amount);
    if estimate <= Utils.toNumber(slippage) then
        Utils.result(from, 403, "slippage " .."estimate " ..estimate .."slippage "..slippage)
        return
    end;
    if Utils.toNumber(TokenA) <= 0 then
        Utils.result(from, 403, "No funds available")
        return
    end;
    if Utils.toNumber(TokenA) < estimate then
        Utils.result(from, 403, "Insufficient funds available " .."estimate " ..estimate .."TokenA "..TokenA)
        return
    end;
    local isValid = IsValid(from, TokenBProcess, amount)
    if isValid ~= true then
        Utils.result(from, 403, "Insufficient funds "..estimate)
        return
    end;
    SubstractBalance(from, TokenBProcess, amount);
    AddBalance(from, TokenAProcess, estimate);
    TokenB = TokenB + amount;
    TokenA = TokenA - Utils.toBalanceValue(estimate);
    local liquidity = GetLiquidity();
    if liquidity >= Utils.toNumber(BondingCurve) then
        IsPump = false;
        ao.send({
            Target = Owner,
            Action = "Bonded"
        });
    end
    local _swap = {
        isBuy = true,
        tokenA = tostring(estimate),
        tokenB = tostring(amount),
        timestamp = timestamp
    };
    ao.send({
        Target = Owner,
        Action = "Swap",
        Swap = json.encode(_swap),
        Liquidity = tostring(liquidity),
        TokenA = TokenAProcess
    });
end

function CreditNotice(msg)
    if msg.From == TokenAProcess and TokenA == 0 then
        TokenA = msg.Quantity;
        if TokenA > 0 and TokenB > 0 then
            IsActive = true;
        end;
        return
    end
    if msg.From == TokenBProcess and TokenB == 0 then
        TokenB = msg.Quantity;
        if TokenA > 0 and TokenB > 0 then
            IsActive = true;
        end;
        return
    end
    if not Balances[msg.From] then Balances[msg.From] = {} end;
    if not Balances[msg.From][msg.Sender] then Balances[msg.From][msg.Sender] = msg.Quantity end;
    local balance = Balances[msg.From][msg.Sender];
    Balances[msg.From][msg.Sender] = balance + msg.Quantity;
end

function Info(msg)
    ao.send({
        Target = msg.From,
        Name = msg.Name,
        TokenA = TokenA,
        TokenB = TokenB,
        TokenAProcess = TokenAProcess,
        TokenBProcess = TokenBProcess,
        BondingCurve = BondingCurve,
        TotalShares = TotalShares,
        Precision = Precision,
        FeeRate = FeeRate,
        IsActive = IsActive,
        IsPump = IsPump
    })
end

function Balance(msg)
    if not Balances[TokenAProcess][msg.Tags.Target or msg.From] then Balances[TokenAProcess][msg.Tags.Target or msg.From] = 0 end;
    if not Balances[TokenBProcess][msg.Tags.Target or msg.From] then Balances[TokenBProcess][msg.Tags.Target or msg.From] = 0 end;
    local _balanceA = Balances[TokenAProcess][msg.Tags.Target or msg.From];
    local _balanceB = Balances[TokenBProcess][msg.Tags.Target or msg.From];
    ao.send({
        Target = msg.From,
        Action = "Balance",
        BalanceA = _balanceA,
        BalanceB = _balanceB,
        TokenA = json.encode(TokenInfo[TokenAProcess]),
        TokenB = json.encode(TokenInfo[TokenBProcess]),
        Account = msg.Tags.Target or msg.From,
    })
end

function Withdraw(msg)
    if not Balances[TokenAProcess][msg.From] then Balances[TokenAProcess][msg.From] = 0 end;
    if not Balances[TokenBProcess][msg.From] then Balances[TokenBProcess][msg.From] = 0 end;

    if msg.isTokenA then
        local _balance = Balances[TokenAProcess][msg.From];
        if _balance < msg.Quantity then
            Utils.result(msg.From, 403, "Insufficient Funds")
            return
        end;
        Balances[TokenAProcess][msg.From] = Utils.subtract(_balance, msg.Quantity);
        ao.send({
            Target = TokenAProcess,
            Action = "Transfer",
            Recipient = msg.Recipient,
            Quantity = msg.Quantity,
        });
    else
        local _balance = Balances[TokenBProcess][msg.From];
        if _balance < msg.Quantity then
            Utils.result(msg.From, 403, "Insufficient Funds")
            return
        end;
        Balances[TokenBProcess][msg.From] = Utils.subtract(_balance, msg.Quantity);
        ao.send({
            Target = TokenBProcess,
            Action = "Transfer",
            Recipient = msg.Recipient,
            Quantity = msg.Quantity,
        });
    end
end

function IsValid(owner, token, amount)
    if not Balances[token] then Balances[token] = {} end;
    if not Balances[token][owner] then Balances[token][owner] = 0 end;
    local balance = Balances[token][owner];
    return Utils.toNumber(amount) > 0 and Utils.toNumber(balance) >= Utils.toNumber(amount);
    ---return false
end

function GetRemoveEstimate(share)
    local result = {};
    result.shareA = 0;
    result.shareB = 0;
    result.shareA = Utils.div(Utils.mul(share, TokenA), TotalShares);
    result.shareB = Utils.div(Utils.mul(share, TokenB), TotalShares);
    return result
end

function GetEquivalentTokenAEstimate(amountB)
    return Utils.div(Utils.mul(TokenA, amountB), TokenB)
end

function GetEquivalentTokenBEstimate(amountA)
    return Utils.div(Utils.mul(TokenB, amountA), TokenA)
end

function GetSwapTokenAEstimate(amount)
    local _price = Price();
    local tokenA = Utils.add(TokenA, amount);
    local tokenB = Utils.div(_price,tokenA);
    local amountB = Utils.subtract(TokenB, tokenB);
    if amountB == TokenB then amountB = Utils.subtract(amountB, "1"); end --To ensure that the pool is not completely depleted
    return math.floor(Utils.toNumber(amountB))
end

function GetSwapTokenBEstimate(amount)
    local _price = Price();
    local tokenB = Utils.add(TokenB, amount);
    local tokenA = Utils.div(_price, tokenB);
    local amountA = Utils.subtract(TokenA,tokenA);
    if amountA == TokenA then amountA = Utils.subtract(amountA,"1"); end --To ensure that the pool is not completely depleted
    return math.floor(Utils.toNumber(amountA))
end

function Price()
    return Utils.mul(TokenA, TokenB);
end

function AddBalance(owner, token, amount)
    if not Balances[token] then Balances[token] = {} end;
    if not Balances[token][owner] then Balances[token][owner] = "0" end;
    local _balance = Balances[token][owner];
    Balances[token][owner] = Utils.add(_balance, amount);
end

function SubstractBalance(owner, token, amount)
    local _balance = Balances[token][owner];
    local _amount = _balance - amount;
    Balances[token][owner] = Utils.toBalanceValue(_amount); 
end

function GetLiquidity()
    if TokenA == 0 and TokenB == 0 then return 0 end;
    local _price = Utils.div(TokenB, TokenA);
    local amount = Utils.mul(_price, TokenA);
    return amount + TokenB;
end

function _FeeMachine()
    --setup logic ot handle fee
end

ao.send({
    Target = Owner,
    Action = "Request",
});