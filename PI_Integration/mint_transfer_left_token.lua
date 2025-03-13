local Utils = require('.utils')
local BintUtils = require('utils.bint_utils')

local leftTokenRecipient = ao.id

Balances[leftTokenRecipient] = BintUtils.subtract(MINT_CAPACITY,MintedSupply)

-- To be updated the address
local fairRecipient = "EsS5lIRW_Bb1o_fuKyhhDE0Kr3Z0MgfGQR8JbzdLcTA"

IsTNComing = true
Send({Target=ao.id,Action='Transfer',Recipient=fairRecipient,Quantity=Balances[leftTokenRecipient]})
            
-- Update the total minted supply by summing all user balances
MintedSupply = BintUtils.add(MintedSupply, Balances[leftTokenRecipient])

assert(MintedSupply == MINT_CAPACITY, " Now MintedSupply must equal MINT_CAPACITY")
print(string.format("MintedSupply: %s", MintedSupply))

-- set mint process stop minting
AO_MINT_PROCESS=ao.id