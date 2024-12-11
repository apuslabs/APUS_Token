local Distributor = { _version = "0.0.1" }

local Utils = require('.utils')

--[[
    Function: bindingWallet
    Associates a user's account with a specific wallet address.

    Parameters:
        user (string): The identifier of the user.
        wallet (string): The wallet address to bind to the user.

    Returns:
        nil
]]
Distributor.bindingWallet = function(user, wallet)
  -- Retrieve the deposit record for the user; if none exists, create a new record with default Mint value
  local record = Deposits:getByUser(user) or {
    User = user,
    Mint = "0"
  }
  -- Assign the provided wallet address as the recipient
  record.Recipient = wallet
  -- Upsert (update or insert) the record into the Deposits data store
  Deposits:upsert(record)
end

Distributor.getWallet = function(user)
  local record = Deposits:getByUser(user) or {
    User = user,
    Mint = "0"
  }
  return record.Recipient or ""
end

-- @TEST
Distributor.testSetWallet = function()
  local records = Deposits:getAll()
  Utils.map(function(r)
    r.Recipient = ao.id
    Deposits:upsert(r)
  end, records)
end

return Distributor
