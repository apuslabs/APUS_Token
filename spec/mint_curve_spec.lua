local luaunit = require('libs.luaunit')
luaunit.LuaUnit:setOutputType("tap")
luaunit:setVerbosity(luaunit.VERBOSITY_VERBOSE)

local Utils = require('utils')
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
  end
  print(APUS_MINT_PCT_1)
  print(MintedSupply)
  luaunit.assertEquals(MintedSupply, "170000000003675286333")

  for i = 1, INTERVALS_PER_YEAR * 4 do
    local releaseAmount = Mint.currentMintAmount()
    MintedSupply = BintUtils.add(MintedSupply, releaseAmount)
    MintTimes = MintTimes + 1
  end
  print(APUS_MINT_PCT_2)
  print(MintedSupply)
end

luaunit.LuaUnit.run()
