local Deposits = { _version = "0.0.1" }
local BintUtils = require('utils.bint_utils')
local Logger = require('utils.log')

Deposits.__index = Deposits

-- @param dbAdmin - dbAdmin instances from utils.db_admin
-- @description Creates a new Deposits instance, initializes the Rewards table if not already present.
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

-- @param user - The user whose Mint value is being updated
-- @param mint - The mint value to add to the user's record
-- @description Updates the mint value for a specific user. If no record exists, a new one is created.
function Deposits:updateMintForUser(user, mint)
  assert(type(user) == "string", "User must be a string")
  if string.len(user) == 42 and user ~= string.lower(user) then
    Logger.warn("Deposits:updateMintForUser: Warning: user address " .. user .. " is not lowercase, converting to lowercase.")
    user = string.lower(user)
  end
  local record = self.dbAdmin:select([[select * from Rewards where user = ?]], { user })
  if not record or #record <= 0 then
    -- Check if user is an Arweave address (43 characters)
    if string.len(user) == 43 then
      record = {
        User = user,
        Mint = mint,
        Recipient = user, -- Set Recipient same as User for Arweave addresses
      }
    else
      -- Check if it's an Ethereum address (42 chars starting with 0x)
      if string.match(user, "^0x[0-9a-fA-F]+$") and string.len(user) == 42 then
        Logger.warn("Creating new record with empty recipient for ETH address: " .. user)
        record = {
          User = user,
          Mint = mint,
          Recipient = "",
        }
      else
        Logger.error("Invalid user address format: " .. user)
        error("Dirty data: Invalid user address format") 
      end
    end
  else
    record = record[1]
    record.Mint = BintUtils.add(record.Mint, mint)
  end
  self:upsert(record)
end

-- @param user - The user to fetch data for
-- @returns The record for the specified user, or nil if no record exists
-- @description Retrieves a specific user's record from the Rewards table.
function Deposits:getByUser(user)
  assert(type(user) == "string", "User must be a string")
  if string.len(user) == 42 and user ~= string.lower(user) then
    Logger.warn("Deposits:getByUser: Warning: user address " .. user .. " is not lowercase, converting to lowercase.")
    user = string.lower(user)
  end
  local res = self.dbAdmin:select([[SELECT * FROM Rewards where User = ?]], { user })
  if not res or #res <= 0 then
    return nil
  else
    return res[1]
  end
end

-- @returns A table containing all reward records
-- @description Retrieves all records from the Rewards table.
function Deposits:getAll()
  return self.dbAdmin:select([[SELECT * FROM Rewards]], {})
end

-- @returns A table containing records of users with non-zero mint and assigned recipient
-- @description Retrieves all users who have a non-zero mint value and a recipient assigned.
function Deposits:getToAllocateUsers()
  return self.dbAdmin:select([[SELECT * FROM Rewards where Mint != '0' and Recipient != '']], {})
end

-- @param record - The record to be inserted or updated in the Rewards table
-- @description Inserts a new record or updates an existing one in the Rewards table.
function Deposits:upsert(record)
  assert(type(record) == "table", "input must be table")
  assert(record.Recipient ~= nil, "Recipient is required")
  assert(record.User ~= nil, "User is required")
  if type(record.User) == "string" and string.len(record.User) == 42 and record.User ~= string.lower(record.User) then
    Logger.warn("Deposits:upsert: Warning: record.User " .. record.User .. " is not lowercase, converting to lowercase.")
    record.User = string.lower(record.User)
  end
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

-- @description Clears all mint values from the Rewards table, setting them to '0'
function Deposits:clearMint()
  self.dbAdmin:apply("UPDATE Rewards set Mint = '0'", {});
end

return Deposits
