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
-- Initial balance for the process
Balances = Balances or {}
-- Total supply of tokens: 1_000_000_000 Apus Tokens; 1_000_000_000_000_000_000 with denomination
TotalSupply = "1000000000000000000000"
-- Flag indicating if transfer is enabled
IsTNComing = IsTNComing or false

--[[
     Add handlers for each incoming Action defined by the ao Standard Token Specification
   ]]
--

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
    if msg.reply then
        msg.reply({ Data = json.encode(Balances) })
    else
        msg.reply({ Data = json.encode(Balances) })
    end
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
    Handler: Minted Supply
    Returns the minted supply of tokens
]]
Token.mintedSupply = function(msg)
    msg.reply({ Data = MintedSupply })
end

--[[
    Helper function to parse CSV data
    Returns a table of recipient and amount pairs
]]
local function parse_csv(data)
    local result = {}
    for line in data:gmatch("[^\r\n]+") do
        local recipient, amount = line:match("([^,]+),([^,]+)")
        if recipient and amount then
            table.insert(result, {recipient, amount})
        end
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

    -- Parse CSV data
  local rawRecords = parse_csv(msg.Data)
  assert(rawRecords and #rawRecords > 0, 'No transfer entries found in CSV')
  
  -- Validate entries and calculate total
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
  
  -- Check if sender has enough balance
  if not Balances[msg.From] then Balances[msg.From] = "0" end
  
  if not (bint(totalQuantity) <= bint(Balances[msg.From])) then
    msg.reply({
      Action = 'Transfer-Error',
      ['Message-Id'] = msg.Id,
      Error = 'Insufficient Balance!'
    })
    return
  end
  
  -- Execute all transfers
  local balanceUpdates = {}
  
  -- Calculate all balance changes
  for _, entry in ipairs(transferEntries) do
    local recipient = entry.Recipient
    local quantity = entry.Quantity
    
    if not Balances[recipient] then Balances[recipient] = "0" end
    
    if not balanceUpdates[recipient] then
      balanceUpdates[recipient] = utils.add(Balances[recipient], quantity)
    else
      balanceUpdates[recipient] = utils.add(balanceUpdates[recipient], quantity)
    end
  end
  
  -- Apply the balance changes atomically
  Balances[msg.From] = utils.subtract(Balances[msg.From], totalQuantity)
  for recipient, newBalance in pairs(balanceUpdates) do
    Balances[recipient] = newBalance
  end
  
  -- Only send notices if Cast tag is not set
  if not msg.Cast then
    -- Format transfer entries for JSON
    local recipientsData = {}
    for _, entry in ipairs(transferEntries) do
      table.insert(recipientsData, {
        recipient = entry.Recipient,
        quantity = entry.Quantity
      })
    end
    
    -- Create Batch-Debit-Notice for the sender
    local batchDebitNotice = {
      Action = 'Batch-Debit-Notice',
      Count = tostring(#transferEntries),
      Total = totalQuantity,
      Data = json.encode(recipientsData)
    }
    
    -- Add forwarded tags to the debit notice
    for tagName, tagValue in pairs(msg) do
      if string.sub(tagName, 1, 2) == "X-" then
        batchDebitNotice[tagName] = tagValue
      end
    end
    
    -- Send Batch-Debit-Notice to sender
    msg.reply(batchDebitNotice)
    
    -- Create Batch-Credit-Notice
    local batchCreditNotice = {
      Action = 'Batch-Credit-Notice',
      Sender = msg.From,
      Count = tostring(#transferEntries),
      Total = totalQuantity,
      Data = json.encode(recipientsData)
    }
    
    -- Add forwarded tags to the credit notice
    for tagName, tagValue in pairs(msg) do
      if string.sub(tagName, 1, 2) == "X-" then
        batchCreditNotice[tagName] = tagValue
      end
    end
    
    -- Send Batch-Credit-Notice (to the process itself for potential handling)
    msg.reply(batchCreditNotice)
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
