Mint = { _version = "0.0.1" }
-- 假设bint库正确安装，并且支持所需的操作
local bint = require('bint')(256)
local json = require('json')

local utils = {
    add = function(a, b)
        return tostring(bint(a) + bint(b))
    end,
    subtract = function(a, b)
        return tostring(bint(a) - bint(b))
    end,
    multiply = function(a, b)
        -- 假设bint支持乘法，如果不支持，需要实现
        return tostring(bint(a) * bint(b))
    end,
    divide = function(a, b)
        -- 假设bint支持除法并返回浮点数，如果不支持，需要实现
        return tonumber(bint(a) / bint(b))
    end,
    toBalanceValue = function(a)
        return tostring(bint(a))
    end,
    toNumber = function(a)
        return tonumber(a)
    end
}

-- 初始化参数
TOTAL_SUPPLY = "1000000000000000000000"    -- 1,000,000,000,000,000,000,000 (1e21)
T0_SUPPLY = "920000000000000000000"        -- 920,000,000,000,000,000,000 (9.2e20)

-- 5 MIN REWARD SUPPLY PERCENT
-- APUS_Mint_PCT = 21, 243, 598 / 10,000,000,000,000 = 0.0019422
APUS_MINT_PCT_1 = 194218390
APUS_MINT_PCT_2 = 164733613
APUS_UNIT = 100000000000000

-- 定义每年的间隔数和每月的间隔数
INTERVALS_PER_YEAR = 365.25 * 24 * 12    -- 8766个1小时间隔 
DAYS_PER_MONTH = 30.4375                    -- 平均每月天数
INTERVALS_PER_MONTH = math.floor(DAYS_PER_MONTH * 24 * 12 + 0.5) -- ≈8766个间隔

-- Circulating Supply
MintedSupply = MintedSupply or "0"

Mint.simulateRelease = function(input)
    assert(input.futureTime or input.cycleNo, "Param futureTime and cycleNo cannot both be empty.")
    assert(input.futureTime == nil or type(input.futureTime) == "number", "futureTime should be of number type." )
    assert(input.cycleNo == nil or type(input.cycleNo) == "number", "futureTime should be of number type.")
    
    local mintedSupply = MintedSupply
    if input.futureTime then
        local currentTime = os.time()
        local cycleNo = 1
        local lastMonthMintedSupply = "0"
        local lastFourYearMintedSupply = "0"
        while currentTime + cycleNo * 300 < input.futureTime do
            local remainingSupply = utils.subtract(T0_SUPPLY, mintedSupply)
            local pct = 0
            if cycleNo <= 105192 then
                pct = APUS_MINT_PCT_1
            else
                pct = APUS_MINT_PCT_2
            end
            local reward = utils.toBalanceValue(bint(remainingSupply) * bint(pct) // bint(APUS_UNIT))
            mintedSupply = utils.add(reward, mintedSupply)
            cycleNo = cycleNo + 1
            if cycleNo % INTERVALS_PER_MONTH == 0 and cycleNo / INTERVALS_PER_MONTH <= 12 then
                local monthlyReleasedNum = utils.subtract(mintedSupply, lastMonthMintedSupply)
                local monthlyReleasePct = bint(monthlyReleasedNum) * 100 / TOTAL_SUPPLY
                local currentReleasePct = bint(mintedSupply) * 100 / TOTAL_SUPPLY
                lastFourYearMintedSupply = mintedSupply
                lastMonthMintedSupply = mintedSupply
                print(string.format("第 %2d 个月释放代币数量: %s 枚，占总供应量的 %.6f%%, 目前已释放 %.6f%%, Cycle %s",
                    cycleNo // INTERVALS_PER_MONTH, monthlyReleasedNum / 10 ^ 12, monthlyReleasePct, currentReleasePct,
                    cycleNo))
            end

            if cycleNo >= INTERVALS_PER_YEAR * 5 and cycleNo % (INTERVALS_PER_YEAR * 4) == INTERVALS_PER_YEAR then
                local fourYearReleaseNum = utils.subtract(mintedSupply, lastFourYearMintedSupply)
                local fourYearReleasePct = bint(fourYearReleaseNum) * 100 / TOTAL_SUPPLY
                local currentReleasePct = bint(mintedSupply) * 100 / TOTAL_SUPPLY
                lastFourYearMintedSupply = mintedSupply
                print(string.format("%2d - %2d 年释放代币数量: %s 枚，占总供应量的 %.6f%%, 目前已释放 %.6f%%, Cycle %s",
                (cycleNo) // INTERVALS_PER_YEAR - 3, (cycleNo) // INTERVALS_PER_YEAR, fourYearReleaseNum / 10 ^ 12,
                    fourYearReleasePct, currentReleasePct, cycleNo))
            end
        end
        print("Ended")
    end

end

return Mint