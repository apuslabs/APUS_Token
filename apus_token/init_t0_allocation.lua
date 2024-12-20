-- ============================================================
-- WARNING: DO NOT MODIFY THIS FILE AFTER INITIAL DEPLOYMENT!
--
-- This file is designed to be used only once during the
-- initialization process. Any modification to this file
-- may lead to being executed again, which can
-- cause Token BROKEN.
-- ============================================================
local Utils = require('.utils')
local BintUtils = require('utils.bint_utils')

local Logger = require('utils.log')

-- If T0 allocation is done
T0Allocated = T0Allocated or false

-- This function is used for allocating APUS tokens to T0 users.
function T0Allocate()
  if not T0Allocated then
    T0Allocated = true
    local beforeSupply = MintedSupply
    -- set balance for each user
    Utils.map(function(r)
      Balances[r.Author] = BintUtils.add(Balances[r.Author] or "0", r.Amount)
    end, T0_ALLOCATION)

    -- set minted supply
    MintedSupply = Utils.reduce(function(acc, value)
      return BintUtils.add(acc, value)
    end, "0", Utils.values(Balances))

    Logger.info(string.format('Allocated %s to %d users, current minted supply: %s',
      BintUtils.subtract(MintedSupply, beforeSupply), #T0_ALLOCATION, MintedSupply))
  end
end

return T0Allocate
