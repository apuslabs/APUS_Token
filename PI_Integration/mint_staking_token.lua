local Utils = require('.utils')
local BintUtils = require('utils.bint_utils')

local stakingTokenAmount = "120000000000000000000"

-- To be updated the address 
Balances["vtlJ35Z3--epovDI2Cw4swXvsK6PT8h90sfAcx8blQM"] = stakingTokenAmount

            
-- Update the total minted supply by summing all user balances
MintedSupply = BintUtils.add(MintedSupply, stakingTokenAmount)

print(string.format("MintedSupply: %s", MintedSupply))