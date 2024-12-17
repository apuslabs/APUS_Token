-- AO Addresses
AO_MINT_PROCESS = "LPK-D_3gZkXtia6ywwU1wRwgFOZ-eLFRMP9pfAFRfuw"
APUS_STATS_PROCESS = "zmr4sqL_fQjjvHoUJDkT8eqCiLFEM3RV5M96Wd59ffU"
APUS_MINT_TRIGGER = "zmr4sqL_fQjjvHoUJDkT8eqCiLFEM3RV5M96Wd59ffU"
AO_RECEIVER = ao.id

-- Minting cycle interval in seconds
MINT_COOL_DOWN = 300

-- The moment the process starts to process with mint reports
StartMintTime = StartMintTime or 0

-- Tokenomics
Name = "Apus"
Ticker = "Apus"
Logo = "SBCCXwwecBlDqRLUjb8dYABExTJXLieawf7m2aBJ-KY"

-- Current minting mode ("ON" or "OFF"), ON: auto-mint; OFF: manual-mint
MODE = MODE or "ON"
--T0 token receivers
T0_ALLOCATION = {
  -- 1% to liquidity
  { Author = "Liquidity_Address",      Amount = "10000000000000000000" },

  -- 5% to pool bootstrap
  { Author = "Pool_Bootstrap_Address", Amount = "50000000000000000000" },

  -- 2% to contributors
  { Author = "Contributor_1",          Amount = "1000000000000000000" },
  { Author = "Contributor_2",          Amount = "1000000000000000000" },
  { Author = "Contributor_3",          Amount = "1000000000000000000" },
  { Author = "Contributor_4",          Amount = "1000000000000000000" },
  { Author = "Contributor_5",          Amount = "1000000000000000000" },
  { Author = "Contributor_6",          Amount = "1000000000000000000" },
  { Author = "Contributor_7",          Amount = "1000000000000000000" },
  { Author = "Contributor_8",          Amount = "1000000000000000000" },
  { Author = "Contributor_9",          Amount = "1000000000000000000" },
  { Author = "Contributor_10",         Amount = "1000000000000000000" },
  { Author = "Contributor_11",         Amount = "1000000000000000000" },
  { Author = "Contributor_12",         Amount = "1000000000000000000" },
  { Author = "Contributor_13",         Amount = "1000000000000000000" },
  { Author = "Contributor_14",         Amount = "1000000000000000000" },
  { Author = "Contributor_15",         Amount = "1000000000000000000" },
  { Author = "Contributor_16",         Amount = "1000000000000000000" },
  { Author = "Contributor_17",         Amount = "1000000000000000000" },
  { Author = "Contributor_18",         Amount = "1000000000000000000" },
  { Author = "Contributor_19",         Amount = "1000000000000000000" },
  { Author = "Contributor_20",         Amount = "1000000000000000000" }
}

return {}
