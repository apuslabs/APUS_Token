local Distributor = { _version = "0.0.1" }

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

--[[
    Function: getWallet
    Retrieves the wallet address associated with a user.

    Parameters:
        user (string): The identifier of the user.

    Returns:
        string: The wallet address associated with the user, or an empty string if no wallet address is found.
]]
Distributor.getWallet = function(user)
  local record = Deposits:getByUser(user) or {
    User = user,
    Mint = "0"
  }
  -- If no wallet is associated, return an empty string
  return record.Recipient or ""
end

return Distributor
