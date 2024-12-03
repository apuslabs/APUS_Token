local BintUtils = { _version = "0.0.1" }
local bint = require('.bint')(256)

BintUtils.add = function(a, b)
  return tostring(bint(a) + bint(b))
end
BintUtils.subtract = function(a, b)
  return tostring(bint(a) - bint(b))
end
BintUtils.multiply = function(a, b)
  return tostring(bint(a) * bint(b))
end
BintUtils.divide = function(a, b)
  return tonumber(bint(a) / bint(b))
end
BintUtils.toBalanceValue = function(a)
  return tostring(bint(a))
end
BintUtils.toNumber = function(a)
  return tonumber(a)
end

return BintUtils
