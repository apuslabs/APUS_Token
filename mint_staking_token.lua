local Utils = require('.utils')
local BintUtils = require('apus_token.utils.bint_utils')

local stakingTokenAmount = "120000000000000000000"

-- To be updated the address 
Balances["U-vRZXZP3tmczr8JOW_J1wqE1KFZo3YheKF5wYBcl1Y"] = stakingTokenAmount

            
-- Update the total minted supply by summing all user balances
MintedSupply = BintUtils.add(MintedSupply, stakingTokenAmount)

print(string.format("MintedSupply: %s", MintedSupply))