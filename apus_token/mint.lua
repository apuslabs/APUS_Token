local Mint = { _version = "0.0.1" }
local Utils = require('.utils')
local bint = require('.bint')(256)
local BintUtils = require('utils.bint_utils')

-- -- Initialize
MINT_CAPACITY = "1000000000000000000000" -- 1,000,000,000,000,000,000,000 (1e21) 10 billion
ApusStatisticsProcess = ApusStatisticsProcess or ""

-- 5 MIN REWARD SUPPLY PERCENT
-- APUS_Mint_PCT = 21, 243, 598 / 10,000,000,000,000 = 0.0019422
APUS_MINT_PCT_1 = 19421654225
APUS_MINT_PCT_2 = 16473367976
APUS_MINT_UNIT = 10000000000000000

-- Use the average value, not the real year days and month days
INTERVALS_PER_YEAR = 365.25 * 24 * 12                            -- 105192
DAYS_PER_MONTH = 30.4375                                         -- average days of the month in one year
INTERVALS_PER_MONTH = math.floor(DAYS_PER_MONTH * 24 * 12 + 0.5) -- 8766

-- Circulating Supply
MintedSupply = MintedSupply or "80000000000000000000"
MintTimes = MintTimes or 1

MINT_COOL_DOWN = 300
LastMintTime = LastMintTime or 0

MODE = MODE or "OFF"

Mint.batchUpdate = function(mintReportList)
    Utils.map(function(mintReport)
        Deposits:updateMintForUser(mintReport.User, mintReport.Mint)
    end, mintReportList)
    return "OK"
end

Mint.currentMintAmount = function()
    local pct = APUS_MINT_PCT_1
    if MintTimes > INTERVALS_PER_YEAR then
        pct = APUS_MINT_PCT_2
    end
    local remainingSupply = BintUtils.subtract(MINT_CAPACITY, MintedSupply)
    local releaseAmount = BintUtils.toBalanceValue(bint(remainingSupply) * bint(pct) // bint(APUS_MINT_UNIT))
    return releaseAmount
end

Mint.mint = function(msg)
    local status, err = pcall(function()
        if LastMintTime ~= 0 and msg.Timestamp - LastMintTime < MINT_COOL_DOWN then
            print("Not cool down yet")
            return "Not cool down yet"
        end
        if msg.Action == "Cron" and MODE == "OFF" then
            print("Not Minting by CRON untils MODE is set to ON")
            return "Not Minting by CRON untils MODE is set to ON"
        end
        local times = (msg.Timestamp - LastMintTime) // MINT_COOL_DOWN
        if LastMintTime == 0 then
            times = 1
        end
        local deposits = Deposits:getToAllocateUsers()
        if not deposits or #deposits == 0 then
            print("No users in the pool.")
            return "No users in the pool."
        end
        for i = 1, times do
            local releaseAmount = Mint.currentMintAmount()
            local depositsWithReward = Allocator:compute(deposits, releaseAmount)
            Utils.map(function(r)
                Balances[r.Recipient] = BintUtils.add(Balances[r.Recipient] or "0", r.Reward)
            end, depositsWithReward)
            MintedSupply = Utils.reduce(function(acc, v)
                return BintUtils.add(acc, v)
            end, "0", Utils.values(Balances))
        end

        MintTimes = MintTimes + times
        Deposits:clearMint()
        if LastMintTime == 0 then
            LastMintTime = msg.Timestamp
        else
            LastMintTime = (msg.Timestamp - LastMintTime) // MINT_COOL_DOWN * MINT_COOL_DOWN + LastMintTime
        end
        collectgarbage('collect')
    end)
    if err then
        print(err)
        return err
    end
    return "OK"
end

function Mint.mintBackUp(msg)
    Mint.mint({ Timestamp = msg.Timestamp })
end

function Mint.isCronBackup(msg)
    if msg.Action == "Cron" then
        return false
    end
    if msg.Action == "Eval" then
        return false
    end
    if Mint == "OFF" then
        return false
    end
    return "continue"
end

return Mint
