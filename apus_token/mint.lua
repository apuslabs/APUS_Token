local Mint = { _version = "0.0.1" }

-- Import necessary modules
local Utils = require('.utils')
local bint = require('.bint')(256)
local BintUtils = require('utils.bint_utils')

-- -- Initialize Constants

-- MINT_CAPACITY represents the total minting capacity in the smallest denomination (e.g., wei)
-- 1,000,000,000,000,000,000,000 (1e21) 10 billion
MINT_CAPACITY = "1000000000000000000000"

-- APUS_MINT_PCT_1 and APUS_MINT_PCT_2 represent different stages of minting percentages
-- APUS_MINT_PCT_1 represents the first year minting percentages (17%)
-- APUS_MINT_PCT_2 represents 4-year halving from the next year minting percentages
APUS_MINT_PCT_1 = 19421654225
APUS_MINT_PCT_2 = 16473367976
-- Base unit for percentage calculations: 10_000_000_000_000_000
APUS_MINT_UNIT = 10000000000000000

-- Time-related Constants
-- Using average values for years and months instead of actual calendar days

-- Approx. 105192 intervals per year
INTERVALS_PER_YEAR = 365.25 * 24 * 12
-- Average days per month
DAYS_PER_MONTH = 30.4375
-- Approx. 8766 intervals per month
INTERVALS_PER_MONTH = math.floor(DAYS_PER_MONTH * 24 * 12 + 0.5)

-- Circulating Supply Variables
-- Initial minted supply in smallest denomination
MintedSupply = MintedSupply or "0"
-- Number of times minting has occurred
MintTimes = MintTimes or 1

-- Timestamp of the last minting
LastMintTime = LastMintTime or 0

return Mint
