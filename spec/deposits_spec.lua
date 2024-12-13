local luaunit = require('libs.luaunit')
luaunit.LuaUnit:setOutputType("tap")
luaunit:setVerbosity(luaunit.VERBOSITY_VERBOSE)

TestDeposits = {}

Deposits = nil

function TestDeposits:setup()
  local sqlite3 = require('lsqlite3')
  MintDb = sqlite3.open_memory()
  DbAdmin = require('utils.db_admin').new(MintDb)
  Deposits = require('dal.deposits').new(DbAdmin)
end

function TestDeposits:testUpsert()
  -- not exists record
  local r = {
    User = "0x7300782D46E385B1D0B4e831D48c4224F502ECb9",
    Recipient = "",
    Mint = "1111"
  }
  Deposits:upsert(r)
  local res = Deposits:getByUser("0x7300782D46E385B1D0B4e831D48c4224F502ECb9") or {}
  luaunit.assertEquals(res.User, r.User)
  luaunit.assertEquals(res.Recipient, r.Recipient)
  luaunit.assertEquals(res.Mint, r.Mint)

  r.Recipient = "AAA"
  Deposits:upsert(r)
  res = Deposits:getByUser("0x7300782D46E385B1D0B4e831D48c4224F502ECb9") or {}
  luaunit.assertEquals(res.User, r.User)
  luaunit.assertEquals(res.Recipient, r.Recipient)
  luaunit.assertEquals(res.Mint, r.Mint)

  r.Mint = "222"
  Deposits:upsert(r)
  res = Deposits:getByUser("0x7300782D46E385B1D0B4e831D48c4224F502ECb9") or {}
  luaunit.assertEquals(res.User, r.User)
  luaunit.assertEquals(res.Recipient, r.Recipient)
  luaunit.assertEquals(res.Mint, r.Mint)
end

function TestDeposits:testUpdateMintForUser()
  Deposits:updateMintForUser("0x7300782D46E385B1D0B4e831D48c4224F502ECb9", "100")
  local res = Deposits:getByUser("0x7300782D46E385B1D0B4e831D48c4224F502ECb9") or {}
  luaunit.assertEquals(res.Mint, "100")
  luaunit.assertEquals(res.Recipient, "")
  luaunit.assertEquals(res.User, "0x7300782D46E385B1D0B4e831D48c4224F502ECb9")

  Deposits:updateMintForUser("0x7300782D46E385B1D0B4e831D48c4224F502ECb9", "200")
  local res = Deposits:getByUser("0x7300782D46E385B1D0B4e831D48c4224F502ECb9") or {}
  luaunit.assertEquals(res.Mint, "300")
  luaunit.assertEquals(res.Recipient, "")
  luaunit.assertEquals(res.User, "0x7300782D46E385B1D0B4e831D48c4224F502ECb9")
end

luaunit.LuaUnit.run()
