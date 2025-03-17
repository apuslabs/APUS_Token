local luaunit = require('libs.luaunit')
luaunit.LuaUnit:setOutputType("tap")
luaunit:setVerbosity(luaunit.VERBOSITY_VERBOSE)

TestDeposits = {}

Deposits = nil
SQLite3 = nil

function TestDeposits:setup()
  SQLite3 = require('lsqlite3')
  MintDb = SQLite3.open_memory()
  DbAdmin = require('utils.db_admin').new(MintDb)
  Deposits = require('dal.deposits').new(DbAdmin)
  print(collectgarbage("count"))
  
end

function TestDeposits:testUpsert()
  -- not exists record
  local r = {
    User = "0x7300782d46e385b1d0b4e831d48c4224f502ecb9",
    Recipient = "",
    Mint = "1111"
  }
  Deposits:upsert(r)
  local res = Deposits:getByUser("0x7300782d46e385b1d0b4e831d48c4224f502ecb9") or {}
  luaunit.assertEquals(res.User, r.User)
  luaunit.assertEquals(res.Recipient, r.Recipient)
  luaunit.assertEquals(res.Mint, r.Mint)

  r.Recipient = "AAA"
  Deposits:upsert(r)
  res = Deposits:getByUser("0x7300782d46e385b1d0b4e831d48c4224f502ecb9") or {}
  luaunit.assertEquals(res.User, r.User)
  luaunit.assertEquals(res.Recipient, r.Recipient)
  luaunit.assertEquals(res.Mint, r.Mint)

  r.Mint = "222"
  Deposits:upsert(r)
  res = Deposits:getByUser("0x7300782d46e385b1d0b4e831d48c4224f502ecb9") or {}
  luaunit.assertEquals(res.User, r.User)
  luaunit.assertEquals(res.Recipient, r.Recipient)
  luaunit.assertEquals(res.Mint, r.Mint)

end


function Table_size(tbl)
  local count = 0
  local mem = 0
  for k, v in pairs(tbl) do
      count = count + 1
      mem = mem + #tostring(k) + #tostring(v)
  end
  return count, mem
end

-- ... existing code ...

function TestDeposits:testMemoryUsage()
  print("Initial memory:", collectgarbage("count"))
  -- Create and upsert 100 records
  for i = 1, 1000 do
    local r = {
      User = string.format("0x%040x", i),  -- Generate unique ETH address
      Recipient = string.format("recipient_%d", i),
      Mint = tostring(i * 1000)
    }
    Deposits:upsert(r)
    
    if i % 100 == 0 then
      collectgarbage("collect")
      print(string.format("After %d records - Memory: %f KB", i, collectgarbage("count")))
    end
  end

  -- Print final statistics
  collectgarbage("collect")
  print("Final memory:", collectgarbage("count"))
  
  local loaded = debug.getregistry()._LOADED
  local count, mem = Table_size(loaded)
  print(string.format("Table _LOADED has %d entries, approx %d bytes", count, mem))
end


function TestDeposits:testUpdateMintForUser()
  Deposits:updateMintForUser("0x7300782d46e385b1d0b4e831d48c4224f502ecb9", "100")
  local res = Deposits:getByUser("0x7300782d46e385b1d0b4e831d48c4224f502ecb9") or {}
  luaunit.assertEquals(res.Mint, "100")
  luaunit.assertEquals(res.Recipient, "")
  luaunit.assertEquals(res.User, "0x7300782d46e385b1d0b4e831d48c4224f502ecb9")

  Deposits:updateMintForUser("0x7300782d46e385b1d0b4e831d48c4224f502ecb9", "200")
  local res = Deposits:getByUser("0x7300782d46e385b1d0b4e831d48c4224f502ecb9") or {}
  luaunit.assertEquals(res.Mint, "300")
  luaunit.assertEquals(res.Recipient, "")
  luaunit.assertEquals(res.User, "0x7300782d46e385b1d0b4e831d48c4224f502ecb9")
end

luaunit.LuaUnit.run()
