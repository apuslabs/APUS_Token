local utils = require('.utils')
local bintUtils = require('utils.bint_utils')
local bint = require('.bint')(256)
local json = require('json')

APUS_MINT_PROCESS = APUS_MINT_PROCESS or "wvVpl-Tg8j15lfD5VrrhyWRR1AQnoFaMMrfgMYES1jU"

CycleInfo = CycleInfo or {}
Capacity = Capacity or 1 -- Take the average level of the past 1 cycle(s).

TotalMint = TotalMint or "0"
AssetStaking = AssetStaking or {}
AssetAOAmount = AssetAOAmount or {}
AssetWeight = AssetWeight or {}

MintedSupply = MintedSupply or "0"
MintCapacity = "1000000000000000000000"

UserMint = UserMint or {}

local function isMintReportFromAPUSToken(msg)
  return msg.Action == "Report.Mint" and msg.From == APUS_MINT_PROCESS
end

local function getTotalMint(reportList)
  return utils.reduce(function(acc, value)
    return bintUtils.add(acc, value.Mint)
  end, "0", reportList
  )
end

local function getAssetStaking(mintReports)
  local res = {}
  utils.map(function(mr)
    if res[mr.Token] == nil then
      res[mr.Token] = mr.Amount
    else
      res[mr.Token] = bintUtils.add(res[mr.Token], mr.Amount)
    end
  end, mintReports)
  return res
end

local function getAssetAOAmount(mintReports)
  local res = {}
  utils.map(function(mr)
    if res[mr.Token] == nil then
      res[mr.Token] = mr.Mint
    else
      res[mr.Token] = bintUtils.add(res[mr.Token], mr.Mint)
    end
  end, mintReports)
  return res
end

local function getAssetWeight(aoAmount, staking)
  local res = {}
  local keys = utils.keys(aoAmount)
  utils.map(function(k)
    res[k] = bintUtils.toBalanceValue(bint(aoAmount[k]) * bint(10 ^ 18) // bint(staking[k]))
  end, keys)
  return res
end

local function updateAssetStaking(update)
  local tokens = utils.keys(AssetStaking)
  utils.map(function(t)
    AssetStaking[t] = bintUtils.toBalanceValue((bint(AssetStaking[t]) * bint(Capacity - 1) + bint(update[t])) //
      bint(Capacity))
  end, tokens)
end

local function updateAssetAOAmount(update)
  local tokens = utils.keys(AssetAOAmount)
  utils.map(function(t)
    AssetAOAmount[t] = bintUtils.toBalanceValue((bint(AssetAOAmount[t]) * bint(Capacity - 1) + bint(update[t])) //
      bint(Capacity))
  end, tokens)
end

local function updateAssetWeight(update)
  local tokens = utils.keys(AssetWeight)
  utils.map(function(t)
    AssetWeight[t] = bintUtils.toBalanceValue((bint(AssetWeight[t]) * bint(Capacity - 1) + bint(update[t])) //
      bint(Capacity))
  end, tokens)
end

local function updateUserMint(mintReports)
  local newUserMint = {}
  utils.map(function(mr)
    newUserMint[mr.User] = bintUtils.add(UserMint[mr.User] or "0", mr.Mint)
  end, mintReports)
  UserMint = newUserMint
end

Handlers.add("Cron", "Cron", function(msg)
  Send({
    Target = APUS_MINT_PROCESS,
    Action = "Minted-Supply"
  }).onReply(function(replyMsg)
    MintedSupply = replyMsg.Data
  end)

  Send({
    Target = APUS_MINT_PROCESS,
    Action = "Mint.Mint"
  })
end)

Handlers.add("Report.Mint", isMintReportFromAPUSToken, function(msg)
  local status, err = pcall(function()
    if #CycleInfo >= Capacity then
      table.remove(CycleInfo, 1) -- 删除第一个元素
    end
    local mintReports = msg.Data

    local totalMint = getTotalMint(mintReports)

    if TotalMint == "0" then
      TotalMint = totalMint
    else
      TotalMint = bintUtils.toBalanceValue((bint(TotalMint) * bint(Capacity - 1) + bint(totalMint)) // bint(Capacity))
    end
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

    updateUserMint(mintReports)
    table.insert(CycleInfo, {
      TotalMint = totalMint,
      AssetStaking = assetStaking,
      AssetAOAmount = assetAOAmount,
      AssetWeight = assetWeight
    })
  end)
  if err then
    print("Error: " .. err)
    return
  end
end)

Handlers.add("User.Get-Estimated-Apus-Token", "User.Get-Estimated-Apus-Token", function(msg)
  local status, err = pcall(function()
    local token = msg.Token
    local amount = msg.Amount
    assert(token ~= nil, "Param token not exists")
    assert(amount ~= nil, "Param amount not exists")
    assert(AssetWeight[token] ~= nil, "Token not support")

    local weight = AssetWeight[token]
    local predictedAOMinted = bintUtils.toBalanceValue(bintUtils.multiply(weight, amount) // bint(10 ^ 18))
    local percent = bint(predictedAOMinted) / (bintUtils.add(predictedAOMinted, TotalMint))

    local predictedMontlyReward = bintUtils.toBalanceValue(bintUtils.toBalanceValue((bint(MintCapacity) -
      bint(MintedSupply)) * 17 // 1000))

    local res = bintUtils.toBalanceValue(
      bint(predictedMontlyReward) * bint(predictedAOMinted) // (bint(predictedAOMinted) + bint(TotalMint)))
    msg.reply({ Data = res })
  end)
  if err then
    print("Error: " .. err)
    return
  end
end)


Handlers.add("User.Get-User-Estimated-Apus-Token", "User.Get-User-Estimated-Apus-Token", function(msg)
  local status, err = pcall(function()
    local targetUser = msg.User

    assert(targetUser ~= nil, "Param target user not exists")

    local share = UserMint[targetUser] or "0"
    local totalShare = TotalMint

    print(share)
    local predictedMontlyReward = bintUtils.toBalanceValue(bint(bintUtils.subtract(MintCapacity,
      MintedSupply)) * 17 // 1000)
    local res = bintUtils.toBalanceValue(bint(predictedMontlyReward) * bint(share) // bint(totalShare))
    print(res)
    msg.reply({ Data = res })
  end)
  if err ~= nil then
    print("Error: " .. err)
    return
  end
end)
