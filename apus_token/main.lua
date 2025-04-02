-- Initialization Script for Minting and Handlers

-- Import necessary modules
local json            = require('json')
local Utils           = require('.utils')
local BintUtils       = require('utils.bint_utils')
local ao              = require('ao')

-- Constants
INITIAL_MINT_AMOUNT   = "80000000000000000000" -- 80,000,000 tokens with denomination

Token                 = require('token')
Logger                = require('utils.log')

require('config')

-- Handlers for various token actions
Handlers.add('token.transfer', Handlers.utils.hasMatchingTag("Action", "Transfer"), Token.transfer)
Handlers.add("token.info", Handlers.utils.hasMatchingTag("Action", "Info"), Token.info)
Handlers.add("token.balance", Handlers.utils.hasMatchingTag("Action", "Balance"), Token.balance)
Handlers.add("token.balances", Handlers.utils.hasMatchingTag("Action", "Balances"), Token.balances)
Handlers.add("token.totalSupply", Handlers.utils.hasMatchingTag("Action", "Total-Supply"), Token.totalSupply)
Handlers.add("token.burn", Handlers.utils.hasMatchingTag("Action", "Burn"), Token.burn)

Handlers.add("metrics", Handlers.utils.hasMatchingTag("Action", "Metrics"), function(msg)
  msg.reply({
    Data = json.encode({
      AO_RECEIVER = AO_RECEIVER,
      LogLevel = LogLevel,
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
