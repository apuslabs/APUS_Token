local json = require("json")
local Utils = require(".utils")

local bint = require(".bint")(256)
local BintUtils = require("utils.bint_utils")
local Allocator = { _version = "0.0.1" }

function Allocator:compute(deposits, reward)
    local totalMint = Utils.reduce(function(acc, r)
        return BintUtils.add(acc, r.Mint)
    end, "0", deposits)

    local left = reward

    Utils.map(function(r)
        r.Reward = BintUtils.toBalanceValue(bint(reward) * bint(r.Mint) // bint(totalMint))
        left = BintUtils.subtract(left, r.Reward)
        return r
    end, deposits)

    if left == reward then
        -- TODO No ao minted
        return
    end

    if bint(left) > 0 then
        deposits[1].Reward = BintUtils.add(deposits[1].Reward, left)
    end

    return deposits
end

return Allocator
