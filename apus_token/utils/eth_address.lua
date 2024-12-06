local crypto = require(".crypto")

local EthAddressUtils = { _version = "0.0.1" }

-- Function to convert address to checksum address
function EthAddressUtils.toChecksumAddress(address)
  -- Remove the "0x" prefix and convert to lowercase
  address = string.lower(address:sub(3))

  -- Calculate the Keccak-256 hash
  local hash = crypto.digest.keccak256(address).asHex()

  local checksumAddress = "0x"

  -- Decide the character case based on the hash value
  for i = 1, #address do
    local char = address:sub(i, i)
    local hashByte = tonumber(hash:sub(i, i), 16)

    if hashByte > 7 then
      checksumAddress = checksumAddress .. string.upper(char)
    else
      checksumAddress = checksumAddress .. char
    end
  end

  return checksumAddress
end

return EthAddressUtils
