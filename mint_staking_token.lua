local Utils = require('.utils')
local BintUtils = require('apus_token.utils.bint_utils')

Balances["U-vRZXZP3tmczr8JOW_J1wqE1KFZo3YheKF5wYBcl1Y"] = "120000000000000000000"

            
-- Update the total minted supply by summing all user balances
MintedSupply = Utils.reduce(function(acc, v)
    return BintUtils.add(acc, v)
end, "0", Utils.values(Balances))

print(string.format("MintedSupply: %s", MintedSupply))