-- [[
--     Tokenomics.
-- ]]
Token = { _version = "0.0.1" }

local json = require("json")
local bint = require(".bint")(256)

local utils = {
    add = function(a, b)
        return tostring(bint(a) + bint(b))
    end,
    subtract = function(a, b)
        return tostring(bint(a) - bint(b))
    end,
    toBalanceValue = function(a)
        return tostring(bint(a))
    end,
    toNumber = function(a)
        return tonumber(a)
    end
}

--[[
     Initialize State

     ao.id is equal to the Process.Id
   ]]
--
Variant = "0.0.3"

-- token should be idempotent and not change previous state updates
Denomination = Denomination or 12
Balances = Balances or { [ao.id] = "80000000000000000000" }
-- 1_000_000_000 Apus Tokens
-- 1_000_000_000_000_000_000 Armstrongs
TotalSupply = "1000000000000000000000"
Name = "Apus"
Ticker = "Apus"
-- @TODO: Logo
Logo = Logo or "SBCCXwwecBlDqRLUjb8dYABExTJXLieawf7m2aBJ-KY"

IsTNComing = IsTNComing or false

--[[
     Add handlers for each incoming Action defined by the ao Standard Token Specification
   ]]
--

--[[
     Info
   ]]
--
Token.info = function(msg)
    print("Return Info")
    Send({
        Target = msg.From,
        Name = Name,
        Ticker = Ticker,
        Logo = Logo,
        Denomination = tostring(Denomination),
        -- @TODO: Mirror service of the process
        -- ['Balance-Mirror'] = "ptCu-Un-3FF8sZ5zNMYg43zRgSYAGVkjz2Lb0HZmx2M",
        -- ['Balances-Mirror'] = "ptCu-Un-3FF8sZ5zNMYg43zRgSYAGVkjz2Lb0HZmx2M",

        -- @TODO: Unnecessary
        -- MintCount = tostring(MintCount),
        Action = "Info-Response"
    })
end


--[[
     Balance
   ]]
--
Token.balance = function(msg)
    local bal = "0"

    -- If not Recipient is provided, then return the Senders balance
    if (msg.Tags.Recipient and Balances[msg.Tags.Recipient]) then
        bal = Balances[msg.Tags.Recipient]
    elseif msg.Tags.Target and Balances[msg.Tags.Target] then
        bal = Balances[msg.Tags.Target]
    elseif Balances[msg.From] then
        bal = Balances[msg.From]
    end

    ao.send({
        Target = msg.From,
        Balance = bal,
        Ticker = Ticker,
        Account = msg.Tags.Recipient or msg.From,
        Data = bal
    })
end

--[[
     Balances
   ]]
--
Token.balances = function(msg)
    -- if msg.Format  == "CSV" then
    --   Send({Target = msg.From, Data = Utils.reduce(function (csv, key)
    --     csv = csv .. key .. "," .. Balances[key] .. "\n"
    --     return csv
    --   end, "", Utils.keys(Balances))})
    --   print('got data')
    --   return "ok"
    -- end
    -- ao.send({ Target = msg.From, Data = Balances })
    Send({ Target = msg.From, Data = "{}", Note = "Feature disabled" })
end
--[[
     Transfer
   ]]
--
Token.transfer = function(msg)
    local status, err = pcall(function()
        assert(IsTNComing, "Cannot transfer until TN")
        assert(type(msg.Recipient) == "string", "Recipient is required!")
        assert(type(msg.Quantity) == "string", "Quantity is required!")
        assert(bint(msg.Quantity) > bint(0), "Quantity must be greater than 0")

        if not Balances[msg.From] then Balances[msg.From] = "0" end
        if not Balances[msg.Recipient] then Balances[msg.Recipient] = "0" end

        if bint(msg.Quantity) <= bint(Balances[msg.From]) then
            Balances[msg.From] = utils.subtract(Balances[msg.From], msg.Quantity)
            Balances[msg.Recipient] = utils.add(Balances[msg.Recipient], msg.Quantity)

            --[[
          Only send the notifications to the Sender and Recipient
          if the Cast tag is not set on the Transfer message
        ]]
            --
            if not msg.Cast then
                -- Debit-Notice message template, that is sent to the Sender of the transfer
                local debitNotice = {
                    Target = msg.From,
                    Action = "Debit-Notice",
                    Recipient = msg.Recipient,
                    Quantity = msg.Quantity,
                    Data = Colors.gray ..
                        "You transferred " ..
                        Colors.blue ..
                        msg.Quantity .. Colors.gray .. " to " .. Colors.green .. msg.Recipient .. Colors.reset
                }
                -- Credit-Notice message template, that is sent to the Recipient of the transfer
                local creditNotice = {
                    Target = msg.Recipient,
                    Action = "Credit-Notice",
                    Sender = msg.From,
                    Quantity = msg.Quantity,
                    Data = Colors.gray ..
                        "You received " ..
                        Colors.blue ..
                        msg.Quantity .. Colors.gray .. " from " .. Colors.green .. msg.From .. Colors.reset
                }

                -- Add forwarded tags to the credit and debit notice messages
                for tagName, tagValue in pairs(msg) do
                    -- Tags beginning with "X-" are forwarded
                    if string.sub(tagName, 1, 2) == "X-" then
                        debitNotice[tagName] = tagValue
                        creditNotice[tagName] = tagValue
                    end
                end

                -- Send Debit-Notice and Credit-Notice
                ao.send(debitNotice)
                ao.send(creditNotice)
            end
        else
            ao.send({
                Target = msg.From,
                Action = "Transfer-Error",
                ["Message-Id"] = msg.Id,
                Error = "Insufficient Balance!"
            })
        end
    end)
    if err then
        Send({ Target = msg.From, Data = err })
        return err
    end
    return "OK"
end

--[[
     Total Supply
   ]]
--
Token.totalSupply = function(msg)
    assert(msg.From ~= ao.id, "Cannot call Total-Supply from the same process!")

    ao.send({
        Target = msg.From,
        Action = "Total-Supply",
        Data = TotalSupply,
        Ticker = Ticker
    })
end

Token.mintedSupply = function(msg)
    Send({ Target = msg.From, Data = MintedSupply })
    print("Id: " .. msg.From .. " Requested Minted Supply: " .. MintedSupply)
end

--[[
 Burn
]] --
Token.burn = function(msg)
    assert(type(msg.Quantity) == "string", "Quantity is required!")
    assert(bint(msg.Quantity) <= bint(Balances[msg.From]), "Quantity must be less than or equal to the current balance!")

    Balances[msg.From] = utils.subtract(Balances[msg.From], msg.Quantity)
    TotalSupply = utils.subtract(TotalSupply, msg.Quantity)

    ao.send({
        Target = msg.From,
        Data = Colors.gray .. "Successfully burned " .. Colors.blue .. msg.Quantity .. Colors.reset
    })
end


return Token
