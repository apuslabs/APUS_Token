-- [[
--   AO Addresses
-- ]]

-- The receiver address for the AO process, typically refers to the AO instance ID (dynamically set)
AO_RECEIVER = "U-vRZXZP3tmczr8JOW_J1wqE1KFZo3YheKF5wYBcl1Y"

-- Log levels to control verbosity of logs
-- Valid log levels: trace, debug, info, warn, error, fatal (default is 'info')
LogLevel = LogLevel or 'info'

-- Tokenomics
Name = "Apus.Network"
Ticker = "APUS"
Logo = "sixqgAh5MEevkhwH4JuCYwmumaYMTOBi3N5_N1GQ6Uc"

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
