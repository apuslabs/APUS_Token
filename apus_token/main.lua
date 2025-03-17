-- Initialization Script for Minting and Handlers

-- Import necessary modules
local sqlite3         = require('lsqlite3')
local json            = require('json')
local Utils           = require('.utils')
local BintUtils       = require('utils.bint_utils')
local EthAddressUtils = require('utils.eth_address')
local ao              = require('ao')

-- Constants
INITIAL_MINT_AMOUNT   = "80000000000000000000" -- 80,000,000 tokens with denomination

-- Initialize in-memory SQLite database or reuse existing one
MintDb                = MintDb or sqlite3.open_memory()

-- Initialize Database Admin with MintDb
DbAdmin               = DbAdmin or require('utils.db_admin').new(MintDb)

-- Initialize Data Access Layer for Deposits
Deposits              = require('dal.deposits').new(DbAdmin)

-- Import core modules
Mint                  = require("mint")
Token                 = require('token')
Allocator             = require('allocator')
Distributor           = require('distributor')
Logger                = require('utils.log')

require('config')

-- Function to verify if a message is a mint report from AO Mint Process
local function isMintReportFromAOMint(msg)
  return msg.Action == "Report.Mint" and msg.From == AO_MINT_PROCESS
end

local function isMintBackupFromProcessOwner(msg)
  return msg.Action == "Mint.Backup" and msg.From == ao.env.Process.Owner
end

local function isCron(msg)
  return msg.Action == "Cron" and (msg.From == ao.env.Process.Owner or msg.From == ao.id)
end

-- Handler for AO Mint Report
Handlers.add("AO-Mint-Report", isMintReportFromAOMint, function(msg)
  if msg.Timestamp // 1000 <= StartMintTime then
    Logger.info(
      "Mint Reports received but not processed (before " .. os.date("%Y-%m-%d %H:%M:%S(UTC)", StartMintTime) .. ").")
    return
  end
  -- Filter reports where the recipient matches the current process ID
  local reports = Utils.filter(function(r)
    return r.Recipient == AO_RECEIVER
  end, msg.Data)
  -- Update message data with filtered reports and forward to APUS_STATS_PROCESS
  msg.Data = reports
  msg.forward(APUS_STATS_PROCESS)
  -- Batch update the Mint records
  Mint.batchUpdate(reports)
end)

-- Cron job handler to trigger minting process (MODE = "ON")
Handlers.add("Mint.Mint", isCron, function(msg)
  if msg.Timestamp // 1000 <= StartMintTime then
    Logger.trace(string.format("Received mint request from Cron, but not processing it.(%s)",
      os.date("%Y-%m-%d %H:%M:%S(UTC)", StartMintTime)))
    return -- receive mint request from cron and return silently before TGE
  end

  require('init_t0_allocation')()

  Mint.mint(msg)
end)

-- Handler for Mint Backup process (MODE = "OFF")
Handlers.add("Mint.Backup", isMintBackupFromProcessOwner, Mint.mintBackUp)

-- Handler to update user's recipient wallet
Handlers.add("User.Update-Recipient", "User.Update-Recipient", function(msg)
  local user = msg.From
  local recipient = msg.Recipient
  -- Bind the user's wallet to the recipient address
  Distributor.bindingWallet(user, recipient)
  -- Reply to the user confirming the binding
  msg.reply({ Data = "Successfully binded" })
end)

-- Handler to retrieve user's recipient wallet
Handlers.add("User.Get-Recipient", "User.Get-Recipient", function(msg)
  local user = msg.User or msg.From
  msg.reply({ Data = Distributor.getWallet(user) })
end)

-- Handler to get user's balance
Handlers.add("User.Balance", "User.Balance", function(msg)
  local user = msg.Recipient
  assert(user ~= nil, "Recipient required")
  -- Convert user address to checksum format
  user = EthAddressUtils.toChecksumAddress(user)
  -- Retrieve deposit record for the user
  local record = Deposits:getByUser(user) or {}
  local recipient = record.Recipient
  local res = Balances[user] or "0"
  if recipient then
    -- If recipient exists, add balances and reply
    msg.reply({ Data = BintUtils.add(res, Balances[recipient] or "0") })
  else
    -- If no recipient, reply with the user's balance
    msg.reply({ Data = res })
  end
end)

-- Handlers for various token actions
Handlers.add('token.transfer', Handlers.utils.hasMatchingTag("Action", "Transfer"), Token.transfer)
Handlers.add("token.info", Handlers.utils.hasMatchingTag("Action", "Info"), Token.info)
Handlers.add("token.balance", Handlers.utils.hasMatchingTag("Action", "Balance"), Token.balance)
Handlers.add("token.balances", Handlers.utils.hasMatchingTag("Action", "Balances"), Token.balances)
Handlers.add("token.totalSupply", Handlers.utils.hasMatchingTag("Action", "Total-Supply"), Token.totalSupply)
Handlers.add("token.burn", Handlers.utils.hasMatchingTag("Action", "Burn"), Token.burn)
Handlers.add("token.mintedSupply", Handlers.utils.hasMatchingTag("Action", "Minted-Supply"), Token.mintedSupply)

Handlers.add("metrics", Handlers.utils.hasMatchingTag("Action", "Metrics"), function(msg)
  msg.reply({
    Data = json.encode({
      AO_MINT_PROCESS = AO_MINT_PROCESS,
      APUS_STATS_PROCESS = APUS_STATS_PROCESS,
      AO_RECEIVER = AO_RECEIVER,
      MINT_COOL_DOWN = MINT_COOL_DOWN,
      StartMintTime = StartMintTime,
      LogLevel = LogLevel,
      MODE = MODE,
      MintedSupply = MintedSupply,
      MintTimes = MintTimes,
      Initialized = Initialized,
      T0Allocated = T0Allocated,
      LastMintTime = LastMintTime,
      IsTNComing = IsTNComing
    })
  })
end)

-- Initialization flag to prevent re-initialization
Initialized = Initialized or false
-- Immediately Invoked Function Expression (IIFE) for initialization logic
(function()
  if Initialized == false then
    Initialized = true
  else
    print("Already Initialized. Skip Initialization.")
    return
  end
  print("Initializing ...")

  -- check if the sum is 8% of the total supply
  local sum = Utils.reduce(function(acc, value)
    return BintUtils.add(acc, value.Amount)
  end, "0", T0_ALLOCATION)
  assert(sum == INITIAL_MINT_AMOUNT, "Initiali Mint Amount Not Equal to 80000000000000000000")
end)()
