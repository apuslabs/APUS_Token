local sqlite3 = require('lsqlite3')
local json = require('json')
local Utils = require('.utils')
local BintUtils = require('utils.bint_utils')

MintDb = MintDb or sqlite3.open_memory()
DbAdmin = DbAdmin or require('utils.db_admin').new(MintDb)

Deposits = require('dal.deposits').new(DbAdmin)

Mint = require("mint")
Token = require('token')
Allocator = require('allocator')
Distributor = require('distributor')

AO_MINT_PROCESS = "LPK-D_3gZkXtia6ywwU1wRwgFOZ-eLFRMP9pfAFRfuw"

local function isMintReportFromAOMint(msg)
  return msg.Action == "Report.Mint" and msg.From == AO_MINT_PROCESS
end

Handlers.add("AO-Mint-Report", isMintReportFromAOMint, function(msg)
end)
Handlers.add("AO-Mint-Report-test", "Report.Mint", function(msg)
  local reports = json.decode(msg.Data)
  local reportList = Utils.filter(function(r)
    return r.Recipient == ao.id
  end, reports)
  -- print(reportList)
  Mint.batchUpdate(reportList)
end)
Handlers.add("Cron", "Cron", Mint.onCronTick)
Handlers.add("Mint", "Mint", Mint.mint)

Handlers.add("Distributor-bindingWallet", "Binding-Wallet", function(msg)
  local user = msg.From
  local recipient = msg.Recipient
  Distributor.bindingWallet(user, recipient)
  msg.reply({ Data = "Successfully binded" })
end)

Handlers.add("User.Balance", "User.Balance", function(msg)
  local user = msg.Recipient
  if not user then
    msg.reply({ Data = "Error: Recipient not found." })
    return
  end
  local record = Deposits:getByUser(user) or {}
  local recipient = record.Recipient
  local res = Balances[user] or "0"
  if not recipient then
    msg.reply({ Data = res })
    return
  else
    msg.reply({ Data = BintUtils.add(res, Balances[recipient] or "0") })
  end
end)

-- No token transfers...
-- Handlers.add('token.transfer', Handlers.utils.hasMatchingTag("Action", "Transfer"), token.transfer)
Handlers.add("token.info", Handlers.utils.hasMatchingTag("Action", "Info"), Token.info)
Handlers.add("token.balance", Handlers.utils.hasMatchingTag("Action", "Balance"), Token.balance)
Handlers.add("token.balances", Handlers.utils.hasMatchingTag("Action", "Balances"), Token.balances)
Handlers.add("token.totalSupply", Handlers.utils.hasMatchingTag("Action", "Total-Supply"), Token.totalSupply)
Handlers.add("token.burn", Handlers.utils.hasMatchingTag("Action", "Burn"), Token.burn)
Handlers.add("token.mintedSupply", Handlers.utils.hasMatchingTag("Action", "Minted-Supply"), Token.mintedSupply)

return {}
