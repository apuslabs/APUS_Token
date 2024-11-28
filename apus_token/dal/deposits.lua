local Deposits = { _version = "0.0.1" }
local BintUtils = require('utils.bint_utils')
local Utils = require('.utils')
local bint = require('.bint')(256)

Deposits.__index = Deposits

-- @param dbAdmin - dbAdmin instances from @rakis/DbAdmin
function Deposits.new(dbAdmin)
  local self = setmetatable({}, Deposits)
  self.dbAdmin = dbAdmin
  self.dbAdmin:exec([[
CREATE TABLE IF NOT EXISTS Rewards (
  Recipient TEXT NOT NULL,
  User TEXT NOT NULL,
  Mint TEXT NOT NULL,
  PRIMARY KEY (User)
);
  ]])
  return self
end

function Deposits:updateMintForUser(user, mint)
  local record = self.dbAdmin:select([[select * from Rewards where user = ?]], { user })
  if not record or #record <= 0 then
    record = {
      User = user,
      Mint = mint,
      Recipient = "",
    }
  else
    record = record[1]
    record.Mint = BintUtils.add(record.Mint, mint)
  end
  self:upsert(record)
end

function Deposits:getByUser(user)
  local res = self.dbAdmin:select([[SELECT * FROM Rewards where User = ?]], { user })
  if not res or #res <= 0 then
    return nil
  else
    return res[1]
  end
end

function Deposits:getAll()
  return self.dbAdmin:select([[SELECT * FROM Rewards]], {})
end

function Deposits:getToAllocateUsers()
  return self.dbAdmin:select([[SELECT * FROM Rewards where Mint != '0' and Recipient != '']], {})
end

function Deposits:upsert(record)
  assert(type(record) == "table", "input must be table")
  assert(record.Recipient ~= nil, "Recipient is required")
  assert(record.User ~= nil, "User is required")
  assert(record.Mint ~= nil, "Mint is required")

  local results = self.dbAdmin:select([[
    SELECT * FROM Rewards WHERE User = ? ]], { record.User })
  local deposit = #results == 1 and results[1] or nil
  if deposit ~= nil then
    self.dbAdmin:apply('UPDATE Rewards SET  Mint = ?, Recipient = ? WHERE User = ?',
      {
        record.Mint or deposit.Mint,
        record.Recipient,
        record.User
      }
    )
  else
    self.dbAdmin:apply('INSERT INTO Rewards (Recipient, User, Mint) VALUES (?,?,?)', {
      record.Recipient,
      record.User,
      record.Mint
    })
  end
end

function Deposits:clearMint()
  self.dbAdmin:apply("UPDATE Rewards set Mint = '0'", {});
end

return Deposits
