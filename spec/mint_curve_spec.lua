local luaunit = require('libs.luaunit')
luaunit.LuaUnit:setOutputType("tap")
luaunit:setVerbosity(luaunit.VERBOSITY_VERBOSE)

local BintUtils = require('utils.bint_utils')
local bint = require('.bint')(256)
TestMintCurve = {}

Mint = nil

function TestMintCurve:setup()
  local sqlite3 = require('lsqlite3')
  MintDb = sqlite3.open_memory()
  DbAdmin = require('utils.db_admin').new(MintDb)
  Deposits = require('dal.deposits').new(DbAdmin)

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

function TestMintCurve:testCurve()
  for i = 1, INTERVALS_PER_YEAR do
    local releaseAmount = Mint.currentMintAmount()
    MintedSupply = BintUtils.add(MintedSupply, releaseAmount)
    MintTimes = MintTimes + 1
    if i % INTERVALS_PER_MONTH == 0 then
      -- print(APUS_MINT_PCT_1)
      print(MintedSupply)
    end
  end
  luaunit.assertEquals(MintedSupply, "250000000002701730643")

  for i = 1, INTERVALS_PER_YEAR * 4 do
    local releaseAmount = Mint.currentMintAmount()
    MintedSupply = BintUtils.add(MintedSupply, releaseAmount)
    MintTimes = MintTimes + 1
  end
  luaunit.assertEquals(MintedSupply, "625000000007424438463")

  for i = 1, INTERVALS_PER_YEAR * 4 do
    local releaseAmount = Mint.currentMintAmount()
    MintedSupply = BintUtils.add(MintedSupply, releaseAmount)
    MintTimes = MintTimes + 1
  end
  luaunit.assertEquals(MintedSupply, "812500000006748929783")

  for i = 1, INTERVALS_PER_YEAR * 4 do
    local releaseAmount = Mint.currentMintAmount()
    MintedSupply = BintUtils.add(MintedSupply, releaseAmount)
    MintTimes = MintTimes + 1
  end
  luaunit.assertEquals(MintedSupply, "906250000004892744378")

  for i = 1, INTERVALS_PER_YEAR * 4 do
    local releaseAmount = Mint.currentMintAmount()
    MintedSupply = BintUtils.add(MintedSupply, releaseAmount)
    MintTimes = MintTimes + 1
  end
  luaunit.assertEquals(MintedSupply, "953125000003205436078")

  for i = 1, INTERVALS_PER_YEAR * 4 do
    local releaseAmount = Mint.currentMintAmount()
    MintedSupply = BintUtils.add(MintedSupply, releaseAmount)
    MintTimes = MintTimes + 1
  end
  luaunit.assertEquals(MintedSupply, "976562500001982174216")

  for i = 1, INTERVALS_PER_YEAR * 4 do
    local releaseAmount = Mint.currentMintAmount()
    MintedSupply = BintUtils.add(MintedSupply, releaseAmount)
    MintTimes = MintTimes + 1
  end
  luaunit.assertEquals(MintedSupply, "988281250001180739166")

  for i = 1, INTERVALS_PER_YEAR * 4 do
    local releaseAmount = Mint.currentMintAmount()
    MintedSupply = BintUtils.add(MintedSupply, releaseAmount)
    MintTimes = MintTimes + 1
  end
  luaunit.assertEquals(MintedSupply, "994140625000685119568")
end

luaunit.LuaUnit.run()
