local Mint = { _version = "0.0.1" }
local Utils = require('.utils')
local bint = require('.bint')(256)
local BintUtils = require('utils.bint_utils')

-- -- Initialize
MINT_CAPACITY = "1000000000000000000000" -- 1,000,000,000,000,000,000,000 (1e21) 10 billion
ApusStatisticsProcess = ApusStatisticsProcess or ""

-- 5 MIN REWARD SUPPLY PERCENT
-- APUS_Mint_PCT = 21, 243, 598 / 10,000,000,000,000 = 0.0019422
APUS_MINT_PCT_1 = 194218390
APUS_MINT_PCT_2 = 164733613
APUS_UNIT = 100000000000000

-- Use the average value, not the real year days and month days
INTERVALS_PER_YEAR = 365.25 * 24 * 12                            -- 105192
DAYS_PER_MONTH = 30.4375                                         -- average days of the month in one year
INTERVALS_PER_MONTH = math.floor(DAYS_PER_MONTH * 24 * 12 + 0.5) -- 8766

-- Circulating Supply
MintedSupply = MintedSupply or "80000000000000000000"
MintTimes = MintTimes or 1

Mint.batchUpdate = function(mintReportList)
    Utils.map(function(mintReport)
        print(mintReport)
        Deposits:updateMintForUser(mintReport.User, mintReport.Mint)
    end, mintReportList)
    return "OK"
end

Mint.currentMintAmount = function()
    local pct = APUS_MINT_PCT_1
    if MintTimes >= INTERVALS_PER_YEAR then
        pct = APUS_MINT_PCT_2
    end
    MintTimes = MintTimes + 1
    local remainingSupply = BintUtils.subtract(MINT_CAPACITY, MintedSupply)
    local releaseAmount = BintUtils.toBalanceValue(bint(remainingSupply) * bint(pct) // bint(APUS_UNIT))
    return releaseAmount
end

Mint.mint = function()
    local releaseAmount = Mint.currentMintAmount()
    local deposits = Deposits:getToAllocateUsers()

    local depositsWithReward = Allocator:compute(deposits, releaseAmount)

    Utils.map(function(r)
        Balances[r.Recipient] = BintUtils.add(Balances[r.Recipient], r.Reward)
    end, depositsWithReward)

    print('Before: MintedSupply: ' .. MintedSupply)
    local beforeMintedSupply = MintedSupply
    MintedSupply = Utils.reduce(function(acc, v)
        return BintUtils.add(acc, v)
    end, "0", Utils.values(Balances))
    print('After: MintedSupply: ' .. MintedSupply)
    local cost = BintUtils.subtract(MintedSupply, beforeMintedSupply);
    print('Minted: ' .. cost)
    print("releaseAmount: " .. releaseAmount)
    print('Cost' .. BintUtils.subtract(releaseAmount, cost))

    Deposits:clearMint()
    collectgarbage('collect')
end


return Mint
