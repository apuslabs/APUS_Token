-- Import required modules
local utils = require('.utils')               -- Utility functions module
local bintUtils = require('utils.bint_utils') -- Big integer utilities
local bint = require('.bint')(256)            -- Big integer operations with 256-bit precision
local json = require('json')                  -- JSON serialization and deserialization module

-- Set the unique identifier for the APUS mint process
APUS_MINT_PROCESS = APUS_MINT_PROCESS or "wvVpl-Tg8j15lfD5VrrhyWRR1AQnoFaMMrfgMYES1jU"

-- Initialize some global variables representing cycle information, capacity, total mint count, assets, etc.
CycleInfo = CycleInfo or {}             -- Information for the current cycle
Capacity = Capacity or 1                -- Capacity of the cycle, default is 1
TotalMint = TotalMint or "0"            -- Total mint count, initialized to 0
AssetStaking = AssetStaking or {}       -- Asset staking data
AssetAOAmount = AssetAOAmount or {}     -- Asset AO amount data
AssetWeight = AssetWeight or {}         -- Asset weight data

MintedSupply = MintedSupply or "0"      -- Minted supply initialized to 0
MintCapacity = "1000000000000000000000" -- Maximum mint capacity

UserMint = UserMint or {}               -- User-specific mint data

-- Function to check if the mint report is from the APUS mint process
local function isMintReportFromAPUSToken(msg)
  return msg.Action == "Report.Mint" and msg.From == APUS_MINT_PROCESS
end

-- Function to calculate the total mint amount from a list of reports
local function getTotalMint(reportList)
  return utils.reduce(function(acc, value)
    return bintUtils.add(acc, value.Mint) -- Accumulate the total mint amount
  end, "0", reportList)
end

-- Function to calculate the total staking amounts for each asset
local function getAssetStaking(mintReports)
  local res = {}
  utils.map(function(mr)
    if res[mr.Token] == nil then
      -- Initialize staking if the token is not already in the result
      res[mr.Token] = mr.Amount
    else
      -- Add the staking amount for the token
      res[mr.Token] = bintUtils.add(res[mr.Token], mr.Amount)
    end
  end, mintReports)
  return res
end

-- Function to calculate the AO amount for each asset
local function getAssetAOAmount(mintReports)
  local res = {}
  utils.map(function(mr)
    if res[mr.Token] == nil then
      -- Initialize AO amount if the token is not already in the result
      res[mr.Token] = mr.Mint
    else
      -- Add the AO mint amount for the token
      res[mr.Token] = bintUtils.add(res[mr.Token], mr.Mint)
    end
  end, mintReports)
  return res
end

-- Function to calculate the weight for each asset based on AO amount and staking
local function getAssetWeight(aoAmount, staking)
  local res = {}
  local keys = utils.keys(aoAmount)
  -- Calculate weight based on AO amount and staking
  utils.map(function(k)
    res[k] = bintUtils.toBalanceValue(bint(aoAmount[k]) * bint(10 ^ 18) // bint(staking[k]))
  end, keys)
  return res
end

-- Function to update the asset staking data based on the new data (calculated in the current cycle)
local function updateAssetStaking(update)
  local tokens = utils.keys(AssetStaking)
  utils.map(function(t)
    -- Update the staking amount for each token based on the new data
    AssetStaking[t] = bintUtils.toBalanceValue((bint(AssetStaking[t]) * bint(Capacity - 1) + bint(update[t])) //
      bint(Capacity))
  end, tokens)
end

-- Function to update the AO amount data based on the new data
local function updateAssetAOAmount(update)
  local tokens = utils.keys(AssetAOAmount)
  utils.map(function(t)
    AssetAOAmount[t] = bintUtils.toBalanceValue((bint(AssetAOAmount[t]) * bint(Capacity - 1) + bint(update[t])) //
      bint(Capacity)) -- Update the AO amount for each token
  end, tokens)
end

-- Function to update the asset weight data based on the new data
local function updateAssetWeight(update)
  local tokens = utils.keys(AssetWeight)
  utils.map(function(t)
    AssetWeight[t] = bintUtils.toBalanceValue((bint(AssetWeight[t]) * bint(Capacity - 1) + bint(update[t])) //
      bint(Capacity)) -- Update the weight for each token
  end, tokens)
end

-- Function to update the user mint data based on the mint reports
local function updateUserMint(mintReports)
  local newUserMint = {}
  utils.map(function(mr)
    -- Normalize the user address to lower-case for compatibility
    local userAddress = string.lower(mr.User)
    newUserMint[userAddress] = bintUtils.add(UserMint[userAddress] or "0", mr.Mint)
  end, mintReports)
  UserMint = newUserMint
end

-- Cron job handler that periodically requests the minted supply data
Handlers.add("Cron", "Cron", function(msg)
  Send({
    Target = APUS_MINT_PROCESS,
    Action = "Minted-Supply"
  }).onReply(function(replyMsg)
    -- Update the minted supply when the reply is received
    MintedSupply = replyMsg.Data
  end)
end)

-- Handler for mint report messages (i.e., mint actions from APUS token)
Handlers.add("Report.Mint", isMintReportFromAPUSToken, function(msg)
  local status, err = pcall(function()
    if #CycleInfo >= Capacity then
      table.remove(CycleInfo, 1) -- Remove the oldest cycle if the capacity is exceeded
    end
    local mintReports = msg.Data

    -- Calculate total mint
    local totalMint = getTotalMint(mintReports)

    -- Update the total mint value
    if TotalMint == "0" then
      TotalMint = totalMint
    else
      TotalMint = bintUtils.toBalanceValue((bint(TotalMint) * bint(Capacity - 1) + bint(totalMint)) // bint(Capacity))
    end

    -- Calculate and update asset staking, AO amounts, and asset weights
    local assetStaking = getAssetStaking(mintReports)
    if #utils.keys(AssetStaking) == 0 then
      AssetStaking = assetStaking
    else
      updateAssetStaking(assetStaking)
    end

    local assetAOAmount = getAssetAOAmount(mintReports)
    if #utils.keys(AssetAOAmount) == 0 then
      AssetAOAmount = assetAOAmount
    else
      updateAssetAOAmount(assetAOAmount)
    end

    local assetWeight = getAssetWeight(assetAOAmount, assetStaking)
    if #utils.keys(AssetWeight) == 0 then
      AssetWeight = assetWeight
    else
      updateAssetWeight(assetWeight)
    end

    -- Update the user mint data
    updateUserMint(mintReports)

    -- Add the current cycle data to the cycle info
    table.insert(CycleInfo, {
      TotalMint = totalMint,
      AssetStaking = assetStaking,
      AssetAOAmount = assetAOAmount,
      AssetWeight = assetWeight
    })
  end)
  if err then
    print("Error: " .. err) -- Log the error if there's an issue
    return
  end
end)

-- Handler to estimate the APUS token amount based on user input
Handlers.add("User.Get-Estimated-Apus-Token", "User.Get-Estimated-Apus-Token", function(msg)
  local status, err = pcall(function()
    local token = msg.Token
    local amount = msg.Amount
    assert(token ~= nil, "Param token not exists")
    assert(amount ~= nil, "Param amount not exists")
    assert(AssetWeight[token] ~= nil, "Token not support")

    local weight = AssetWeight[token]
    -- Calculate the predicted AO minted based on the amount
    local predictedAOMinted = bintUtils.toBalanceValue(bintUtils.multiply(weight, amount) // bint(10 ^ 18))
    -- Calculate the percentage of AO minted
    local percent = bint(predictedAOMinted) /
        (bintUtils.add(predictedAOMinted, TotalMint))

    -- Calculate the predicted monthly reward based on remaining mint capacity
    local predictedMonthlyReward = bintUtils.toBalanceValue(bintUtils.toBalanceValue((bint(MintCapacity) -
      bint(MintedSupply)) * 17 // 1000))

    -- Calculate the final result based on the predicted AO minted and reward
    local res = bintUtils.toBalanceValue(
      bint(predictedMonthlyReward) * bint(predictedAOMinted) // (bint(predictedAOMinted) + bint(TotalMint)))
    msg.reply({ Data = res }) -- Return the calculated result
  end)
  if err then
    print("Error: " .. err) -- Log any error that occurs
    return
  end
end)

-- Handler to estimate the user's APUS token based on the user's mint share
Handlers.add("User.Get-User-Estimated-Apus-Token", "User.Get-User-Estimated-Apus-Token", function(msg)
  local status, err = pcall(function()
    local targetUser = string.lower(msg.User)  -- convert incoming address to lower-case

    assert(targetUser ~= nil, "Param target user not exists")

    local share = UserMint[targetUser] or "0"
    local totalShare = TotalMint

    -- Calculate the predicted monthly reward based on remaining mint capacity
    local predictedMonthlyReward = bintUtils.toBalanceValue(bint(bintUtils.subtract(MintCapacity,
      MintedSupply)) * 17 // 1000)
    -- Calculate the estimated reward for the user based on their share
    local res = bintUtils.toBalanceValue(bint(predictedMonthlyReward) * bint(share) // bint(totalShare))

    msg.reply({ Data = res }) -- Return the estimated result for the user
  end)
  if err ~= nil then
    print("Error: " .. err)
    return
  end
end)
