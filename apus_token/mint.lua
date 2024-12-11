local Mint = { _version = "0.0.1" }

-- Import necessary modules
local Utils = require('.utils')
local bint = require('.bint')(256)
local BintUtils = require('utils.bint_utils')

-- -- Initialize Constants

-- MINT_CAPACITY represents the total minting capacity in the smallest denomination (e.g., wei)
-- 1,000,000,000,000,000,000,000 (1e21) 10 billion
MINT_CAPACITY = "1000000000000000000000"

-- APUS_MINT_PCT_1 and APUS_MINT_PCT_2 represent different stages of minting percentages
-- APUS_MINT_PCT_1 represents the first year minting percentages (17%)
-- APUS_MINT_PCT_2 represents 4-year halving from the next year minting percentages
APUS_MINT_PCT_1 = 19421654225
APUS_MINT_PCT_2 = 16473367976
-- Base unit for percentage calculations: 10_000_000_000_000_000
APUS_MINT_UNIT = 10000000000000000

-- Time-related Constants
-- Using average values for years and months instead of actual calendar days

-- Approx. 105192 intervals per year
INTERVALS_PER_YEAR = 365.25 * 24 * 12
-- Average days per month
DAYS_PER_MONTH = 30.4375
-- Approx. 8766 intervals per month
INTERVALS_PER_MONTH = math.floor(DAYS_PER_MONTH * 24 * 12 + 0.5)

-- Circulating Supply Variables
-- Initial minted supply in smallest denomination
MintedSupply = MintedSupply or "80000000000000000000"
-- Number of times minting has occurred
MintTimes = MintTimes or 1

-- Timestamp of the last minting
LastMintTime = LastMintTime or 0
TotalMintIsZero = TotalMintIsZero or false

-- Current minting mode ("ON" or "OFF"), ON: auto-mint; OFF: manual-mint
MODE = MODE or "OFF"

--[[
    Function: batchUpdate
    Batch updates minting information according to a list of mint reports.


    Parameters:
        mintReportList (table): A list of mint reports, each containing a User and Mint amount.

    Returns:
        string: "OK" indicating successful update.
]]
Mint.batchUpdate = function(mintReportList)
    -- check if sum of mint equals zero
    local mintSum = Utils.reduce(function(acc, value)
        return BintUtils.add(acc, value.Mint)
    end, "0", mintReportList)
    if mintSum == "0" then
        -- if total mint is zero, set TotalMintIsZero to true for burning
        TotalMintIsZero = true
    end
    -- Iterate over each mint report and update the corresponding user's mint information
    Utils.map(function(mintReport)
        Deposits:updateMintForUser(mintReport.User, mintReport.Mint)
    end, mintReportList)
    return "OK"
end

--[[
    Function: currentMintAmount
    Calculates the current amount of tokens to be minted based on the remaining supply and minting percentages.

    Returns:
        string: The calculated amount to be minted, in the smallest denomination.
]]
Mint.currentMintAmount = function()
    local pct = APUS_MINT_PCT_1
    -- Adjust the minting percentage based on the number of times minting has occurred
    if MintTimes > INTERVALS_PER_YEAR then
        pct = APUS_MINT_PCT_2
    end
    -- Calculate the remaining supply by subtracting minted supply from total capacity
    local remainingSupply = BintUtils.subtract(MINT_CAPACITY, MintedSupply)
    -- Calculate the release amount based on the percentage and unit
    local releaseAmount = BintUtils.toBalanceValue(bint(remainingSupply) * bint(pct) // bint(APUS_MINT_UNIT))
    return releaseAmount
end

--[[
    Function: mint
    Executes the minting process, distributing tokens to users based on current state and configuration.

    Parameters:
        msg (table): Contains information about the minting action, such as Timestamp and Action type.

    Returns:
        string: "OK" if minting is successful, or an error message if it fails.
]]
Mint.mint = function(msg)
    -- Use pcall to safely execute the minting process and catch any runtime errors
    local status, err = pcall(function()
        -- Convert the timestamp from milliseconds to seconds
        local curTime = msg.Timestamp // 1000

        -- Check if the cooldown period has not yet elapsed
        if LastMintTime ~= 0 and curTime - LastMintTime < MINT_COOL_DOWN then
            print("Not cool down yet")
            return "Not cool down yet"
        end

        -- If the action is triggered by Cron and the mode is OFF, do not proceed with minting
        if msg.Action == "Cron" and MODE == "OFF" then
            print("Not Minting by CRON untils MODE is set to ON")
            return "Not Minting by CRON untils MODE is set to ON"
        end

        -- Calculate how many times minting should occur based on the cooldown period
        local times = (curTime - LastMintTime) // MINT_COOL_DOWN
        if LastMintTime == 0 then
            times = 1
        end

        -- Retrieve the list of users eligible for minting
        local deposits = Deposits:getToAllocateUsers()
        if not deposits or #deposits == 0 and not TotalMintIsZero then
            print("No users in the pool.")
            return "No users in the pool."
        end

        if not deposits or #deposits == 0 and TotalMintIsZero then
            -- reset the flag
            TotalMintIsZero = false
            -- total mint is zero, which results in no eligible users. Actually the process received mint reports.
            for i = 1, times do
                -- Determine the amount to be minted in this iteration
                local releaseAmount = Mint.currentMintAmount()
                -- burn the token by adding amount for balance of DEAD address
                Balances["DEAD"] = BintUtils.add(Balances["DEAD"] or "0", releaseAmount)
                -- Update the total minted supply by adding releaseAmount
                MintedSupply = BintUtils.add(MintedSupply, releaseAmount)
                -- Increment the number of times minting has occurred
                MintTimes = MintTimes + 1
            end
        else
            -- Perform minting for the calculated number of times
            for i = 1, times do
                -- Determine the amount to be minted in this iteration
                local releaseAmount = Mint.currentMintAmount()
                -- Compute the reward for each user based on their deposit
                local depositsWithReward = Allocator:compute(deposits, releaseAmount)
                -- Update each user's balance with the calculated reward
                Utils.map(function(r)
                    Balances[r.Recipient] = BintUtils.add(Balances[r.Recipient] or "0", r.Reward)
                end, depositsWithReward)
                -- Update the total minted supply by summing all user balances
                MintedSupply = Utils.reduce(function(acc, v)
                    return BintUtils.add(acc, v)
                end, "0", Utils.values(Balances))
                -- Increment the number of times minting has occurred
                MintTimes = MintTimes + 1
            end

            -- Clear the minting records from the Deposits module
            Deposits:clearMint()
        end

        -- Update the timestamp of the last minting
        if LastMintTime == 0 then
            LastMintTime = curTime
        else
            LastMintTime = (curTime - LastMintTime) // MINT_COOL_DOWN * MINT_COOL_DOWN + LastMintTime
        end

        -- Trigger garbage collection to optimize memory usage
        collectgarbage('collect')
    end)

    -- If an error occurred during the minting process, print and return the error
    if err then
        print(err)
        return err
    end

    -- Return "OK" to indicate successful minting
    return "OK"
end

--[[
    Function: mintBackUp
    Backup function for minting, invokes the main mint function with the provided timestamp.

    Parameters:
        msg (table): Contains the Timestamp required for the minting process.

    Returns:
        string: "OK" if the backup minting is successful, or an error message if it fails.
]]
function Mint.mintBackUp(msg)
    -- Call the main mint function with the provided Timestamp
    Mint.mint({ Timestamp = msg.Timestamp })
end

-- Export the Mint module
return Mint
