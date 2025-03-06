local Utils = require('.utils')
local BintUtils = require('apus_token.utils.bint_utils')

local leftTokenRecipient = ao.id

Balances[leftTokenRecipient] = BintUtils.subtract(MINT_CAPACITY,MintedSupply)

-- to be updated the address
local fairRecipient = "eNen_uiF2CB96PzEymhV60oe3bdJP3ez-H9peEF99_A"
IsTNComing = true
Send({Target=ao.id,Action='Transfer',Recipient=fairRecipient,Quantity=Balances[leftTokenRecipient]})
            
-- Update the total minted supply by summing all user balances
MintedSupply = Utils.reduce(function(acc, v)
    return BintUtils.add(acc, v)
end, "0", Utils.values(Balances))

print(string.format("MintedSupply: %s", MintedSupply))

-- set mint process stop minting
AO_MINT_PROCESS=ao.id