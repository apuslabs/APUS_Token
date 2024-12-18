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
MintedSupply = MintedSupply or "0"
-- Number of times minting has occurred
MintTimes = MintTimes or 1

-- Timestamp of the last minting
LastMintTime = LastMintTime or 0

--[[
    Function: batchUpdate
    Batch updates minting information according to a list of mint reports.


    Parameters:
        mintReportList (table): A list of mint reports, each containing a User and Mint amount.

    Returns:
        string: "OK" indicating successful update.
]]
Mint.batchUpdate = function(mintReportList)
    -- Iterate over each mint report and update the corresponding user's mint information
    Logger.info('Receive mint reports, add mint value for ' .. #mintReportList .. ' users.')
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
            Logger.error(string.format("Mint #%d: Failed, less than five minutes since the last mint(%s).",
                MintTimes, os.date("%Y-%m-%d %H:%M:%S(UTC)", LastMintTime)))
            return
        end

        -- If the action is triggered by Cron and the mode is OFF, do not proceed with minting
        if msg.Action == "Cron" and MODE == "OFF" then
            Logger.error(string.format(
                "Mint #%d: Failed, mint cannot be triggered by a cron task because the MODE is set to OFF.",
                MintTimes))
            return
        end

        -- If the action is triggered by Backup and the mode is ON, do not proceed with minting
        if msg.Action == "Mint.Backup" and MODE == "ON" then
            Logger.error(string.format(
                "Mint #%d: Failed, mint cannot be triggered by backup because the MODE is set to ON.",
                MintTimes))
            return
        end

        -- Calculate how many times minting should occur based on the cooldown period
        local times = (curTime - LastMintTime) // MINT_COOL_DOWN
        if LastMintTime == 0 then
            times = 1
        end

        -- Retrieve the list of users eligible for minting
        local deposits = Deposits:getToAllocateUsers()
        if not deposits or #deposits == 0 then
            Logger.error(string.format(
                "Mint #%d: Failed, no users have contributed a mint, possibly due to no mint reports received.",
                MintTimes))
            return
        end

        -- Perform minting for the calculated number of times
        for i = 1, times do
            -- Determine the amount to be minted in this iteration
            local releaseAmount = Mint.currentMintAmount()
            -- Compute the reward for each user based on their deposit
            local depositsWithReward = Allocator:compute(deposits, releaseAmount)

            local beforeMintedSupply = MintedSupply
            -- Update each user's balance with the calculated reward
            Utils.map(function(r)
                Balances[r.Recipient] = BintUtils.add(Balances[r.Recipient] or "0", r.Reward)
            end, depositsWithReward)
            -- Update the total minted supply by summing all user balances
            MintedSupply = Utils.reduce(function(acc, v)
                return BintUtils.add(acc, v)
            end, "0", Utils.values(Balances))

            Logger.info(string.format(
                "Mint #%d: Suceeded, allocate for %d users, totally allocated %s, currently minted supply %s",
                MintTimes, #depositsWithReward, BintUtils.subtract(MintedSupply, beforeMintedSupply), MintedSupply))
            -- Increment the number of times minting has occurred
            MintTimes = MintTimes + 1
        end

        -- Clear the minting records from the Deposits module
        Deposits:clearMint()
        Logger.trace(string.format('Mint #%d: Clear mint.', MintTimes))

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
    Mint.mint(msg)
end

-- Export the Mint module
return Mint
