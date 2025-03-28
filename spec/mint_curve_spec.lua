local luaunit = require('libs.luaunit')
luaunit.LuaUnit:setOutputType("tap")
luaunit:setVerbosity(luaunit.VERBOSITY_VERBOSE)

local BintUtils = require('utils.bint_utils')
local bint = require('.bint')(256)
TestMintCurve = {}

Mint = nil

function TestMintCurve:setup()
  -- local beforeCount = 0
  -- for key, value in pairs(_G) do
  --     beforeCount = beforeCount + 1
  --     print(key)
  -- end
  -- print(_G["MINT_CAPACITY"])
  -- print('\n\n\n\n\n')
  Mint = require('mint')
  -- local afterCount = 0
  -- for key, value in pairs(_G) do
  --     afterCount = afterCount + 1
  --     print(key)
  -- end
  -- print(beforeCount)
  -- print(afterCount)
  -- luaunit.assertEquals(afterCount - beforeCount, 10)
end

function TestMintCurve:testFirstYear()
  local monthlyMinted = 0
  local t0TotalSupply = "80000000000000000000"
  local apus_unit = bint("1000000000000")

  MintedSupply = t0TotalSupply
  MintTimes = 1
  
    -- 每个月目标比例列表（百分比）
    local monthlyTargetRates = {
      1.55, 1.52, 1.50, 1.48, 1.45, 1.43,
      1.40, 1.38, 1.36, 1.33, 1.31, 1.29
    }

  for i = 1, INTERVALS_PER_YEAR do
    local releaseAmount = Mint.currentMintAmount()
    monthlyMinted = BintUtils.add(monthlyMinted, releaseAmount)
    MintedSupply = BintUtils.add(MintedSupply, releaseAmount)
    MintTimes = MintTimes + 1

    if i % INTERVALS_PER_MONTH == 0 then
      local currentRate = BintUtils.divide(monthlyMinted, MINT_CAPACITY) * 100

      -- 获取当前月的目标比例
      local monthIndex = i // INTERVALS_PER_MONTH
      local targetRate = monthlyTargetRates[monthIndex]

      -- 打印当前月的比例
      print(string.format("Month %d: Minted Rate: %.2f%%, Target Rate: %.2f%%", monthIndex, currentRate, targetRate))

      -- 检查是否符合目标比例
      luaunit.assertTrue(math.abs(currentRate - targetRate) < 0.01)

      monthlyMinted = 0
    end
  end
  
  local firstYearTotal = (bint(MintedSupply) - bint(t0TotalSupply)) // bint(apus_unit)

  luaunit.assertEquals(tostring(firstYearTotal), "170000000")
end

function TestMintCurve:test2To5Years()
  local t1TotalSupply = "250000000000000000000"
  local apus_unit = bint("1000000000000")

  MintedSupply = t1TotalSupply
  MintTimes = INTERVALS_PER_YEAR + 1
  for i = 1, INTERVALS_PER_YEAR * 4 do
    local releaseAmount = Mint.currentMintAmount()
    MintedSupply = BintUtils.add(MintedSupply, releaseAmount)
    MintTimes = MintTimes + 1
  end

  local two2fiveYearsTotal = (bint(MintedSupply) - bint(t1TotalSupply)) // bint(apus_unit)
  luaunit.assertEquals(tostring(two2fiveYearsTotal), "375000000")
end

function TestMintCurve:test6To9Years()
  local t5TotalSupply = "625000000000000000000"
  local apus_unit = bint("1000000000000")

  MintedSupply = t5TotalSupply
  MintTimes = INTERVALS_PER_YEAR * 5 + 1
  for i = 1, INTERVALS_PER_YEAR * 4 do
    local releaseAmount = Mint.currentMintAmount()
    MintedSupply = BintUtils.add(MintedSupply, releaseAmount)
    MintTimes = MintTimes + 1
  end

  local six2NineYearsTotal = (bint(MintedSupply) - bint(t5TotalSupply)) // bint(apus_unit)
  luaunit.assertEquals(tostring(six2NineYearsTotal), "187500000")
end

function TestMintCurve:test10To13Years()
  local t9TotalSupply = "812500000000000000000"
  local apus_unit = bint("1000000000000")

  MintedSupply = t9TotalSupply
  MintTimes = INTERVALS_PER_YEAR * 9 + 1
  for i = 1, INTERVALS_PER_YEAR * 4 do
    local releaseAmount = Mint.currentMintAmount()
    MintedSupply = BintUtils.add(MintedSupply, releaseAmount)
    MintTimes = MintTimes + 1
  end

  local ten2thirteenYearsTotal = (bint(MintedSupply) - bint(t9TotalSupply)) // bint(apus_unit)
  luaunit.assertEquals(tostring(ten2thirteenYearsTotal), "93750000")
end

function TestMintCurve:test14To17Years()
  local t13TotalSupply = "906250000000000000000"
  local apus_unit = bint("1000000000000")

  MintedSupply = t13TotalSupply
  MintTimes = INTERVALS_PER_YEAR * 9 + 1
  for i = 1, INTERVALS_PER_YEAR * 4 do
    local releaseAmount = Mint.currentMintAmount()
    MintedSupply = BintUtils.add(MintedSupply, releaseAmount)
    MintTimes = MintTimes + 1
  end

  local fourteen2seventeenYearsTotal = (bint(MintedSupply) - bint(t13TotalSupply)) // bint(apus_unit)
  luaunit.assertEquals(tostring(fourteen2seventeenYearsTotal), "46875000")
end

luaunit.LuaUnit.run()
