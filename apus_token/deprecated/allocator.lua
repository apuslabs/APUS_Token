local Allocator = { _version = "0.0.1" }

local Utils = require(".utils")
local bint = require(".bint")(256)
local BintUtils = require("utils.bint_utils")

--[[
    Function: compute
    Calculates and distributes rewards to users based on their deposits and the total reward pool.

    Parameters:
        deposits (table): A list of user deposit records, each containing a User, Mint, and optionally Reward.
        reward (string): The total reward pool to be distributed, in the smallest denomination.

    Returns:
        table: The updated list of deposit records with assigned rewards.
]]
function Allocator:compute(deposits, reward)
    -- Ensure deposits is a valid table and reward is a non-negative number (string type)
    assert(type(deposits) == "table", "Expected deposits to be a table.")
    assert(#deposits > 0, "Deposits table should not be empty.")
    assert(type(reward) == "string", "Expected reward to be a string.")
    assert(bint(reward) > 0, "Invalid reward value.")

    -- Calculate the total minted amount from all deposits
    local totalMint = Utils.reduce(function(acc, r)
        return BintUtils.add(acc, r.Mint)
    end, "0", deposits)

    -- Ensure totalMint is valid and not zero
    assert(bint(totalMint) > 0, "Total mint value cannot be less than zero.")

    -- Assign rewards to each deposit based on their proportion of the total mint
    Utils.map(function(r)
        -- Calculate the reward for the current deposit
        r.Reward = BintUtils.toBalanceValue(bint(reward) * bint(r.Mint) // bint(totalMint))
        return r
    end, deposits)

    return deposits
end

return Allocator
