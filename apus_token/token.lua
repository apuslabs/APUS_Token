-- Tokenomics Module
-- Handles token-related operations such as info, balance, transfer, burn, etc.
Token = { _version = "0.0.1" }

local json = require("json")
local bint = require(".bint")(256)

-- Utility functions for arithmetic operations
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

-- Initialize token state variables: ao.id is equal to the Process.Id
Variant = "0.0.3"
-- token should be idempotent and not change previous state updates
Denomination = Denomination or 12

-- Token Info
Name = "Apus.Network"
Ticker = "APUS"
Logo = "sixqgAh5MEevkhwH4JuCYwmumaYMTOBi3N5_N1GQ6Uc"

-- Initial balance for the process
Balances = Balances or {}
-- Total supply of tokens: 1_000_000_000 Apus Tokens; 1_000_000_000_000_000_000 with denomination
TotalSupply = "1000000000000000000000"
-- Flag indicating if transfer is enabled
IsTNComing = IsTNComing or false

--[[
    Handler: Info
    Responds with token information
   ]]
--
Token.info = function(msg)

    msg.reply({
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
    Handler: Balance
    Returns the balance of a user
   ]]
--
Token.balance = function(msg)
    local bal = "0"

    -- Determine which balance to fetch based on provided tags
    if (msg.Tags.Recipient and Balances[msg.Tags.Recipient]) then
        bal = Balances[msg.Tags.Recipient]
    elseif msg.Tags.Target and Balances[msg.Tags.Target] then
        bal = Balances[msg.Tags.Target]
    elseif Balances[msg.From] then
        bal = Balances[msg.From]
    end

    -- Send the balance information back to the requester
    msg.reply({
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
    msg.reply({ Data = json.encode(Balances) })
end

--[[
    Handler: Transfer
    Transfers tokens from one user to another
    Note: Currently disabled until TN (Liquidity Trigger Event) is implemented
   ]]
--
Token.transfer = function(msg)
    local status, err = pcall(function()
        -- Ensure that transfers are enabled
        assert(IsTNComing, "Cannot transfer until TN")
        -- Validate message parameters
        assert(type(msg.Recipient) == "string", "Recipient is required!")
        assert(type(msg.Quantity) == "string", "Quantity is required!")
        assert(bint(msg.Quantity) > bint(0), "Quantity must be greater than 0")
        -- Initialize balances if not present
        if not Balances[msg.From] then Balances[msg.From] = "0" end
        if not Balances[msg.Recipient] then Balances[msg.Recipient] = "0" end
        -- Check if sender has sufficient balance
        if bint(msg.Quantity) <= bint(Balances[msg.From]) then
            -- Subtract from sender and add to recipient
            Balances[msg.From] = utils.subtract(Balances[msg.From], msg.Quantity)
            Balances[msg.Recipient] = utils.add(Balances[msg.Recipient], msg.Quantity)

            --[[
                Only send the notifications to the Sender and Recipient
                if the Cast tag is not set on the Transfer message
            ]]
            --
            -- If the transfer message is not a cast, send notices
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
                -- Update state
                Send({
                  device = 'patch@1.0',
                  balances = Balances
                })
            end
        else
            -- Insufficient balance; send error message
            msg.reply({
                Action = "Transfer-Error",
                ["Message-Id"] = msg.Id,
                Error = "Insufficient Balance!"
            })
        end
    end)
    -- Handle any errors that occurred during the transfer process
    if err then
        Send({ Target = msg.From, Data = err })
        return err
    end
    return "OK"
end

--[[
    Handler: Total Supply
    Returns the total supply of tokens
]] --
Token.totalSupply = function(msg)
    -- Prevent self-calls to avoid potential infinite loops or conflicts
    assert(msg.From ~= ao.id, "Cannot call Total-Supply from the same process!")

    -- Send the total supply information back to the requester
    msg.reply({
        Action = "Total-Supply",
        Data = TotalSupply,
        Ticker = Ticker
    })
end

--[[
    CSV Parser Implementation
    ------------------------
    Simple CSV parser that splits input by newlines and commas
    to create a 2D table of values.
]]
local function parseCSV(csvText)
    local result = {}
    -- Split by newlines and process each line
    for line in csvText:gmatch("[^\r\n]+") do
      local row = {}
      -- Split line by commas and add each value to the row
      for value in line:gmatch("[^,]+") do
        table.insert(row, value)
      end
      table.insert(result, row)
    end
    return result
  end

--[[
    Handler: Batch Transfer
    Transfers tokens from one user to multiple recipients
]]
Token.batchTransfer = function(msg)
    -- Validate the quantity to burn
    assert(IsTNComing, "Cannot batch transfer until TN")
    -- Step 1: Parse CSV data and validate entries
    local rawRecords = parseCSV(msg.Data)
    assert(rawRecords and #rawRecords > 0, 'No transfer entries found in CSV')

    -- Collect valid transfer entries and calculate total
    local transferEntries = {}
    local totalQuantity = "0"

    for i, record in ipairs(rawRecords) do
      local recipient = record[1]
      local quantity = record[2]

      assert(recipient and quantity, 'Invalid entry at line ' .. i .. ': recipient and quantity required')
      assert(string.match(quantity, "^%d+$"), 'Invalid quantity format at line ' .. i .. ': must contain only digits')
      assert(bint.ispos(bint(quantity)), 'Quantity must be greater than 0 at line ' .. i)

      table.insert(transferEntries, {
        Recipient = recipient,
        Quantity = quantity
      })

      totalQuantity = utils.add(totalQuantity, quantity)
    end

    -- Step 2: Check if sender has enough balance
    if not Balances[msg.From] then Balances[msg.From] = "0" end

    if not (bint(totalQuantity) <= bint(Balances[msg.From])) then
      msg.reply({
        Action = 'Transfer-Error',
        ['Message-Id'] = msg.Id,
        Error = 'Insufficient Balance!'
      })
      return
    end

    -- Step 3: Prepare the balance updates
    local balanceUpdates = {}

    -- Calculate all balance changes
    for _, entry in ipairs(transferEntries) do
      local recipient = entry.Recipient
      local quantity = entry.Quantity

      if not Balances[recipient] then Balances[recipient] = "0" end

      -- Aggregate multiple transfers to the same recipient
      if not balanceUpdates[recipient] then
        balanceUpdates[recipient] = utils.add(Balances[recipient], quantity)
      else
        balanceUpdates[recipient] = utils.add(balanceUpdates[recipient], quantity)
      end
    end

    -- Step 4: Apply the balance changes atomically
    Balances[msg.From] = utils.subtract(Balances[msg.From], totalQuantity)
    for recipient, newBalance in pairs(balanceUpdates) do
      Balances[recipient] = newBalance
    end
    -- Update state
    Send({
      device = 'patch@1.0',
      balances = Balances
    })
    -- Step 5: Always send a batch debit notice to the sender
    local batchDebitNotice = {
      Action = 'Batch-Debit-Notice',
      Count = tostring(#transferEntries),
      Total = totalQuantity,
      ['Batch-Transfer-Init-Id'] = msg.Id
    }

    -- Forward any X- tags to the debit notice
    for tagName, tagValue in pairs(msg) do
      if string.sub(tagName, 1, 2) == "X-" then
        batchDebitNotice[tagName] = tagValue
      end
    end

    -- Always send Batch-Debit-Notice to sender
    msg.reply(batchDebitNotice)

    -- Step 6: Send individual credit notices if Cast tag is not set
    if not msg.Cast then
      for _, entry in ipairs(transferEntries) do
        local recipient = entry.Recipient
        local quantity = entry.Quantity

        -- Credit-Notice message template, sent to each recipient
        local creditNotice = {
          Target = recipient,
          Action = 'Credit-Notice',
          Sender = msg.From,
          Quantity = quantity,
          ['Batch-Transfer-Init-Id'] = msg.Id,
          Data = Colors.gray ..
              "You received " ..
              Colors.blue .. quantity .. Colors.gray .. " from " .. Colors.green .. msg.From .. Colors.reset
        }

        -- Forward any X- tags to the credit notices
        for tagName, tagValue in pairs(msg) do
          if string.sub(tagName, 1, 2) == "X-" then
            creditNotice[tagName] = tagValue
          end
        end

        -- Send Credit-Notice to recipient
        Send(creditNotice)
      end
    end
end

--[[
    Handler: Burn
    Burns a specified quantity of tokens from the user's balance
]]
Token.burn = function(msg)
    -- Validate the quantity to burn
    assert(IsTNComing, "Cannot burn until TN")
    assert(type(msg.Quantity) == "string", "Quantity is required!")
    assert(bint(msg.Quantity) <= bint(Balances[msg.From] or "0"),
        "Quantity must be less than or equal to the current balance!")

    -- Subtract the quantity from the user's balance and total supply
    Balances[msg.From] = utils.subtract(Balances[msg.From], msg.Quantity)
    Balances["DEAD"] = utils.add(Balances["DEAD"] or "0", msg.Quantity)

    -- Confirm successful burn to the user
    msg.reply({
        Data = Colors.gray .. "Successfully burned " .. Colors.blue .. msg.Quantity .. Colors.reset
    })
end


return Token
