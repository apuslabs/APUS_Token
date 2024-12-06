local luaunit = require('libs.luaunit')
luaunit.LuaUnit:setOutputType("tap")
luaunit:setVerbosity(luaunit.VERBOSITY_VERBOSE)


local Utils = require(".utils")

local bint = require(".bint")(256)
local BintUtils = require("utils.bint_utils")

Allocator = nil
-- 测试类
TestAllocator = {}

function TestAllocator:setup()
    Allocator = require('allocator')
end

function TestAllocator:testCompute()
    -- prepare the
    local deposits = {
        { User = "0x0d386297c95C7e48db734E3Eb2F476CD73f92E59", Mint = "1000000000000", Recipient = "" },
        { User = "0xdA4Ef9B6d55176ab0760b8fe90152c699C91D16e", Mint = "2000000000000", Recipient = "" },
        { User = "0xd0265Aa8A1b3b409F061F2AE4f39Cdbf1BA3A37a", Mint = "3000000000000", Recipient = "" }
    }
    local reward = "1000000" -- 
    local updatedDeposits = Allocator:compute(deposits, reward)

    
    print(updatedDeposits)
    luaunit.assertNotNil(updatedDeposits)
    luaunit.assertEquals(#updatedDeposits, 3) 
    print("parameter is right ...")

    local distributedTotal = bint(updatedDeposits[1].Reward) + bint(updatedDeposits[2].Reward) + bint(updatedDeposits[3].Reward)
    luaunit.assertEquals(distributedTotal, bint(reward))

    print("reward is right ...")

    
    local totalMint = bint("1000000000000") + bint("2000000000000") + bint("3000000000000")
    luaunit.assertNotEquals(
        updatedDeposits[1].Reward,
        BintUtils.toBalanceValue(bint(reward) * bint("1000000000000") // totalMint)
    )
    print(" user take the left ...")

    luaunit.assertEquals(
        updatedDeposits[2].Reward,
        BintUtils.toBalanceValue(bint(reward) * bint("2000000000000") // totalMint)
    )
    luaunit.assertEquals(
        updatedDeposits[3].Reward,
        BintUtils.toBalanceValue(bint(reward) * bint("3000000000000") // totalMint)
    )

  
end

luaunit.LuaUnit.run()