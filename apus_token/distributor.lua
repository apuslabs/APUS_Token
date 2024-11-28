local Distributor = { _version = "0.0.1" }

local Utils = require('.utils')

Distributor.bindingWallet = function(user, wallet)
  local record = Deposits:getByUser(user) or {
    User = user,
    Mint = "0"
  }
  record.Recipient = wallet
  Deposits:upsert(record)
end

Distributor.testSetWallet = function()
  local records = Deposits:getAll()
  Utils.map(function(r)
    r.Recipient = ao.id
    Deposits:upsert(r)
  end, records)
end

return Distributor
