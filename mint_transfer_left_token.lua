local Utils = require('.utils')
local BintUtils = require('apus_token.utils.bint_utils')

local leftTokenRecipient = ao.id

Balances[leftTokenRecipient] = BintUtils.subtract(MINT_CAPACITY,MintedSupply)

-- To be updated the address
local fairRecipient = "eNen_uiF2CB96PzEymhV60oe3bdJP3ez-H9peEF99_A"

IsTNComing = true
Send({Target=ao.id,Action='Transfer',Recipient=fairRecipient,Quantity=Balances[leftTokenRecipient]})
            
-- Update the total minted supply by summing all user balances
MintedSupply = BintUtils.add(MintedSupply, Balances[leftTokenRecipient])

assert(MintedSupply == MINT_CAPACITY, " Now MintedSupply must equal MINT_CAPACITY")
print(string.format("MintedSupply: %s", MintedSupply))

-- set mint process stop minting
AO_MINT_PROCESS=ao.id