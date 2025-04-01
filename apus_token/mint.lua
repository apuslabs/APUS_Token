local Mint = { _version = "0.0.1" }

-- MINT_CAPACITY represents the total minting capacity in the smallest denomination (e.g., wei)
-- 1,000,000,000,000,000,000,000 (1e21) 10 billion
MINT_CAPACITY = "1000000000000000000000"

-- Circulating Supply Variables
-- Initial minted supply in smallest denomination
MintedSupply = MintedSupply or "0"
-- Number of times minting has occurred
MintTimes = MintTimes or 1

-- Timestamp of the last minting
LastMintTime = LastMintTime or 0

return Mint
