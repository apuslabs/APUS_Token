-- [[
--   AO Addresses
-- ]]
-- Mint process address used for minting operations (dynamically set)
AO_MINT_PROCESS = "LPK-D_3gZkXtia6ywwU1wRwgFOZ-eLFRMP9pfAFRfuw"
-- APUS stats process address used for tracking statistics (dynamically set from runtime config)
APUS_STATS_PROCESS = "hEBzo6Up125OBeCKoz3W12y2CbQESl0Q4xoWkceDR00"
-- The receiver address for the AO process, typically refers to the AO instance ID (dynamically set)
AO_RECEIVER = "wU4TFTVHL8vNuw8tNgab6bimvOh1S-V4I1xkYEQTDFQ"

-- Minting cycle interval (in seconds)
-- Defines the cooldown period between minting cycles, set to 300 seconds (5 minutes)
MINT_COOL_DOWN = 300

-- Start time for mint processing (initially set to a dynamic value if not defined)
-- Marks the moment when minting process begins
StartMintTime = StartMintTime or 1734513300

-- Log levels to control verbosity of logs
-- Valid log levels: trace, debug, info, warn, error, fatal (default is 'info')
LogLevel = LogLevel or 'info'

-- Tokenomics
Name = "Apus"
Ticker = "Apus"
Logo = "FpZ540mGWcWQmiWAWzW4oREUyrF2CxLGwgZwbxhK-9g"

-- Current minting mode: auto-mint or manual-mint
-- ON: auto-mint is enabled, OFF: manual minting required (default is 'ON')
MODE = MODE or "ON"

-- Initial token allocation (T0) for various entities, with allocations dynamically inserted
T0_ALLOCATION = {
  -- 1% allocated to liquidity pool
  { Author = "zxom15ySOXLhpasi8ian4eoKmocUpNpi5BHE1g0Uqas", Amount = "10000000000000000000" },

  -- 5% allocated to pool bootstrap
  { Author = "POJfk-XpD1ghZLIZwuSCD8JFDh_FPOZYbizp5MWxczQ", Amount = "50000000000000000000" },

  -- 2% allocated to contributors
  -- Now test only. Will add all winners' awards during test period before TGE
  { Author = "shUfg1ovwx0J-5y6A4HUOWJ485XHBZXoLe4vS2iOurU", Amount = "10000000000000000000" },
  { Author = "JyQiTvqKIXZczY57PWOnhELUBIIKc56xWAbcM2_MXrk", Amount = "10000000000000000000" }
}

return {}
