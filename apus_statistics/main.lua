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
    return bintUtils.add(acc, value.Yield) -- Accumulate the total mint amount
  end, "0", reportList)
end

-- Function to update the user mint data based on the mint reports
local function updateUserMint(mintReports)
  local newUserMint = {}
  for _, mr in ipairs(mintReports) do
      -- Normalize the user address to lower-case for compatibility
      local userAddress = string.lower(mr.User)
      -- Add to the user's total Mint
      newUserMint[userAddress] = bintUtils.add(newUserMint[userAddress] or "0", mr.Yield)
  end
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
    print('Receive mint reports: ' .. #mintReports .. ' record(s).')

    -- Calculate total mint
    local totalMint = getTotalMint(mintReports)

    -- Update the total mint value
    if TotalMint == "0" then
      TotalMint = totalMint
    else
      TotalMint = bintUtils.toBalanceValue((bint(TotalMint) * bint(Capacity - 1) + bint(totalMint)) // bint(Capacity))
    end

    -- Update the user mint data
    updateUserMint(mintReports)

    -- Add the current cycle data to the cycle info
    table.insert(CycleInfo, {
      TotalMint = totalMint,
    })
  end)
  if err then
    print("Error: " .. err) -- Log the error if there's an issue
    return
  end
end)

-- Handler to estimate the user's APUS token based on the user's mint share
Handlers.add("User.Get-User-Estimated-Apus-Token", "User.Get-User-Estimated-Apus-Token", function(msg)
  local status, err = pcall(function()
    local targetUser = msg.User
    assert(targetUser ~= nil, "Param target user not exists")

    local share = UserMint[targetUser] or "0"
    local totalShare = TotalMint

    -- APUS_MINT_PCT_1 = 19421654225 APUS_MINT_PCT_2 = 16473367976
    -- 1.678% 1.425%
    -- StartMintTime  1734513300
    -- Calculate the predicted monthly reward based on remaining mint capacity
    local pct = 1678
    if msg.Timestamp // 1000 > 1734513300 + 365.25 * 24 * 60 * 60 then
      pct = 1425
      Logger.info("APUS mint pct is 1.425%")    
    end
    local predictedMonthlyReward = bintUtils.toBalanceValue(bint(bintUtils.subtract(MintCapacity,
      MintedSupply)) * pct // 100000)
    -- Calculate the estimated reward for the user based on their share
    local res = bintUtils.toBalanceValue(bint(predictedMonthlyReward) * bint(share) // bint(totalShare))

    msg.reply({ Data = res }) -- Return the estimated result for the user
  end)
  if err ~= nil then
    print("Error: " .. err)
    return
  end
end)
