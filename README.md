# $APUS Token

# 1. Token Distribution Analysis and Implementation

## 1.1 Overview of Distribution Model

### Initial Allocation

- **Community**: 92%
  - 80% (TGE 0%): Community delegating
  - 12% (TGE 0%): Pool Substake
  - 1st year: 17%, then 4-year halving
- **Ecosystem**: 7%
  - 2% (TGE 100%): TestNet
  - 5% (TGE 100%): Pool Bootstrap
- **Liquidity**: 1% (TGE 100%)

## 1.2 AO Token Release Schedule

This document outlines the token release schedule for AO tokens over a 41-year period.

### First Year (TGE + Year 1)

- **TGE (Time 0)**: 8% initial distribution
- **Year 1**: 17% total distribution

### Subsequent Years

- **Years 2-5**: 37.5% total
- **Years 6-9**: 18.75% total
- **Years 10-13**: 9.375% total
- **Years 14-17**: 4.6875% total
- **Following Years**: Continue halving the growth increment

### Data Structure

```lua
local ReleaseSchedule = {
    -- First Year 17% (Monthly Release)
    { epoch_start = 0,       release_per_epoch = "2547" },  -- Jan, 2.2%
    { epoch_start = 8640,    release_per_epoch = "2315" },  -- Feb, 2.0%
    { epoch_start = 17280,   release_per_epoch = "2084" },  -- Mar, 1.8%
    { epoch_start = 25920,   release_per_epoch = "1852" },  -- Apr, 1.6%
    { epoch_start = 34560,   release_per_epoch = "1736" },  -- May, 1.5%
    { epoch_start = 43200,   release_per_epoch = "1620" },  -- Jun, 1.4%
    { epoch_start = 51840,   release_per_epoch = "1505" },  -- Jul, 1.3%
    { epoch_start = 60480,   release_per_epoch = "1344" },  -- Aug, 1.2%
    { epoch_start = 69408,   release_per_epoch = "1232" },  -- Sep, 1.1%
    { epoch_start = 78336,   release_per_epoch = "1120" },  -- Oct, 1.0%
    { epoch_start = 87264,   release_per_epoch = "1120" },  -- Nov, 1.0%
    { epoch_start = 96192,   release_per_epoch = "1008" },  -- Dec, 0.9%

    -- Subsequent Years
    { epoch_start = 105120,  release_per_epoch = "892" },   -- Years 2-5, 9.375%
    { epoch_start = 525600,  release_per_epoch = "446" },   -- Years 6-9, 4.6875%
    { epoch_start = 946080,  release_per_epoch = "223" },   -- Years 10-13, 2.34375%
    { epoch_start = 1366560, release_per_epoch = "111" },   -- Years 14-17, 1.171875%
    { epoch_start = 1787040, release_per_epoch = "55" },    -- Years 18-21, 0.5859375%
    { epoch_start = 2207520, release_per_epoch = "27" },    -- Years 22-25, 0.29296875%
    { epoch_start = 2628000, release_per_epoch = "13" },    -- Years 26-29, 0.146484375%
    { epoch_start = 3048480, release_per_epoch = "6" },     -- Years 30-33, 0.0732421875%
    { epoch_start = 3468960, release_per_epoch = "3" },     -- Years 34-37, 0.03662109375%
    { epoch_start = 3889440, release_per_epoch = "1" }      -- Years 38-41, 0.018310546875%
}
```

1. each epoch is 5 minutes
1. `epoch_start`: The starting epoch number for each release period
1. `release_per_epoch`: The amount of tokens to be released per epoch in that period
1. Each period continues until the next `epoch_start`
1. The final period (Years 38-41) ends at epoch 4,309,920

### Implementation Considerations

1. Use binary search to find the appropriate release rate for any given epoch
2. Release amounts are represented as strings to handle large numbers precisely
3. Each period's release rate remains constant until the next period begins
4. Implement proper overflow checks for epoch calculations
5. All release amounts should be validated against the total supply cap

# How to test

first run `npm run init`

All testcase should be under spec folder

`npm run test -- entry.lua` or
`npm run test`

Every testfile should be end with `_spec.lua`
Every testfile should contains

```lua
local luaunit = require('libs.luaunit')
luaunit.LuaUnit:setOutputType("tap")
luaunit:setVerbosity(luaunit.VERBOSITY_VERBOSE)
luaunit.LuaUnit.run()
```

# How to deploy

Run with aos console:
```
aos [process_name] --sqlite --cron 5-minute

.load apus_token/main.lua

.monitor
```

# AOS console inputs & outputs

### Main

- **MintDb**
  Return the database with memory address.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> MintDb
  sqlite database (0x618f688)
  ```
- **DbAdmin**
  Return the object DbAdmin(it has a member variable called db).
  ```shell
  Apus@aos-2.0.1[Inbox:18]> DbAdmin
  {
   db = sqlite database (0x618f688)
  }
  ```
- **Deposits**
  Return the database connector to deposits.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> Deposits
  {
    dbAdmin = {
      db = sqlite database (0x618f688)
    }
  }
  ```
- **Mint**
  Return the mint module, members are mint-related functions. These functions can be found in `mint.lua`.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> Mint
  {
    currentMintAmount = function: 0x6253280,
    _version = "0.0.1",
    isCronBackup = function: 0x62534e0,
    mint = function: 0x6253220,
    batchUpdate = function: 0x6253140,
    mintBackUp = function: 0x6253480
  }
  ```

- **Token**
  Return the token module, members are token-related functions. These functions can be found in `token.lua`.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> Token
  {
    info = function: 0x6252a00,
    balances = function: 0x6252a60,
    _version = "0.0.1",
    burn = function: 0x62392a0,
    transfer = function: 0x6238fa0,
    mintedSupply = function: 0x6239240,
    totalSupply = function: 0x62391c0,
    balance = function: 0x6253600
  }
  ```

- **Allocator**
  Return the allocator module, members are allocator-related functions. These functions can be found in `allocator.lua`.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> Allocator
  {
    _version = "0.0.1",
    compute = function: 0x6239480
  }
  ```

- **Distributor**
  Return the distributor module, members are distributor-related functions. These functions can be found in `distributor.lua`.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> Distributor
  {
    getWallet = function: 0x6239820,
    bindingWallet = function: 0x6239760,
    _version = "0.0.1",
    testSetWallet = function: 0x6239940
  }
  ```

- **AO_MINT_PROCESS**
  Return the address of AO Mint Process.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> AO_MINT_PROCESS
  LPK-D_3gZkXtia6ywwU1wRwgFOZ-eLFRMP9pfAFRfuw
  ```

- **APUS_STATS_PROCESS**
  Return the address of Apus Stats Process
  ```shell
  Apus@aos-2.0.1[Inbox:18]> APUS_STATS_PROCESS
  zmr4sqL_fQjjvHoUJDkT8eqCiLFEM3RV5M96Wd59ffU
  ```

- **Initialized**
  Return if the process has been initialized.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> Initialized
  true
  ```

### Deposits

- **Deposits.new(DbAdmin)**
  Create a new client to process with the `rewards` table. This will trigger the create table operation. We can directly use the `DbAdmin` as the parameter to create such an instance.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> Deposits.new(DbAdmin)
  {
    dbAdmin = {
      db = sqlite database (0x618f688)
    }
  }
  ```

- **Deposits:updateMintForUser(user, mint)**
  This function is used to add mint for target user record. You can directly use `Deposits` to call the functions. No need to get a new instance of Deposits.
  ```shell
  # select the record first.
  Apus@aos-2.0.1[Inbox:18]> Deposits:getByUser("0xEFb8a39cDcCC482EA0c92450BD0f6DF31201aF55")
  {
    User = "0xEFb8a39cDcCC482EA0c92450BD0f6DF31201aF55",
    Mint = "0",
    Recipient = "JyQiTvqKIXZczY57PWOnhELUBIIKc56xWAbcM2_MXrk"
  }
  # add mint for the user.
  Apus@aos-2.0.1[Inbox:18]> Deposits:updateMintForUser("0xEFb8a39cDcCC482EA0c92450BD0f6DF31201aF55", "2500")
  # select the record again to check Mint.
  Apus@aos-2.0.1[Inbox:18]> Deposits:getByUser("0xEFb8a39cDcCC482EA0c92450BD0f6DF31201aF55")
  {
    User = "0xEFb8a39cDcCC482EA0c92450BD0f6DF31201aF55",
    Mint = "2500",
    Recipient = "JyQiTvqKIXZczY57PWOnhELUBIIKc56xWAbcM2_MXrk"
  }
  ```
  
- **Deposits:getByUser(user)**
  This function is used to select the record of one user.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> Deposits:getByUser("0xEFb8a39cDcCC482EA0c92450BD0f6DF31201aF55")
  {
    User = "0xEFb8a39cDcCC482EA0c92450BD0f6DF31201aF55",
    Mint = "0",
    Recipient = "JyQiTvqKIXZczY57PWOnhELUBIIKc56xWAbcM2_MXrk"
  }
  ```

- **Deposits:getAll()**
  This function returns all the records in `rewards` table.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> Deposits:getAll()
  {
    {
      User = "0x0d386297c95C7e48db734E3Eb2F476CD73f92E59",
      Mint = "0",
      Recipient = ""
    },
    {
      User = "0xdA4Ef9B6d55176ab0760b8fe90152c699C91D16e",
      Mint = "0",
      Recipient = ""
    },
    {
      User = "0xd0265Aa8A1b3b409F061F2AE4f39Cdbf1BA3A37a",
      Mint = "0",
      Recipient = ""
    },
    {
      User = "0x6DCeB0F7Dd6bED4fF190D8cA74F67973C280f4B4",
      Mint = "0",
      Recipient = ""
    },
    {
      User = "0x360d26B78eECB0DC96c3fC4d99512879916b35c4",
      Mint = "0",
      Recipient = ""
    },
    {
      User = "lpJ5Edz_8DbNnVDL0XdbsY9vCOs45NACzfI4jvo4Ba8",
      Mint = "0",
      Recipient = "lpJ5Edz_8DbNnVDL0XdbsY9vCOs45NACzfI4jvo4Ba8"
    },
    {
      User = "0x43C68e2C3Fc96b077d19e503a609a83Cb4D0c6fA",
      Mint = "0",
      Recipient = ""
    },
    {
      User = "0x8f3D0284183aBdBe3345C8cE08Ec81413e82f38F",
      Mint = "0",
      Recipient = "lpJ5Edz_8DbNnVDL0XdbsY9vCOs45NACzfI4jvo4Ba8"
    },
    {
      User = "0x7300782D46E385B1D0B4e831D48c4224F502ECb9",
      Mint = "0",
      Recipient = "lpJ5Edz_8DbNnVDL0XdbsY9vCOs45NACzfI4jvo4Ba8"
    },
    {
      User = "0xEFb8a39cDcCC482EA0c92450BD0f6DF31201aF55",
      Mint = "0",
      Recipient = "JyQiTvqKIXZczY57PWOnhELUBIIKc56xWAbcM2_MXrk"
    }
  }
  ```

- **Deposits:getToAllocateUsers()**
  This functions return the records filtered with the condition that Mint of the record should be greater than zero and recipient cannot be empty.
  ```shell
  # empty because all the records have no mint.
  Apus@aos-2.0.1[Inbox:18]> Deposits:getToAllocateUsers()
  {  }
  # add Mint for the target user.
  Apus@aos-2.0.1[Inbox:18]> Deposits:updateMintForUser("0xEFb8a39cDcCC482EA0c92450BD0f6DF31201aF55", "2500")
  # select again, the record can be found in the result.
  Apus@aos-2.0.1[Inbox:18]> Deposits:getToAllocateUsers()
  {
    {
      User = "0xEFb8a39cDcCC482EA0c92450BD0f6DF31201aF55",
      Mint = "2500",
      Recipient = "JyQiTvqKIXZczY57PWOnhELUBIIKc56xWAbcM2_MXrk"
    }
  }
  ```

- **Deposits:upsert(record)**
  This function can insert(if the record with the record.User does not exist) or update(the record exists) the record.
  ```shell
  # first select, no record found
  Apus@aos-2.0.1[Inbox:18]> Deposits:getByUser("test")
  # upsert the record with User equal to test
  Apus@aos-2.0.1[Inbox:18]> Deposits:upsert({User = "test", Recipient = "", Mint = "0"})
  # second select, can get the record
  Apus@aos-2.0.1[Inbox:18]> Deposits:getByUser("test")
  {
    User = "test",
    Mint = "0",
    Recipient = ""
  }
  # upsert again, this can update the record.Mint
  Apus@aos-2.0.1[Inbox:18]> Deposits:upsert({User = "test", Recipient = "", Mint = "321321"})
  # last select, check if upsert works.
  Apus@aos-2.0.1[Inbox:18]> Deposits:getByUser("test")
  {
    User = "test",
    Mint = "321321",
    Recipient = ""
  }
  ```

- **Deposits:clearMint()**
  This function will clear all the records' Mint value.
  ```shell
  # No users ready for allocation.
  Apus@aos-2.0.1[Inbox:18]> Deposits:getToAllocateUsers()
  {  }
  # add mint for the target user.
  Apus@aos-2.0.1[Inbox:18]> Deposits:updateMintForUser("0xEFb8a39cDcCC482EA0c92450BD0f6DF31201aF55", "2500")
  # check if the user exists in the allocation list.
  Apus@aos-2.0.1[Inbox:18]> Deposits:getToAllocateUsers()
  {
    {
      User = "0xEFb8a39cDcCC482EA0c92450BD0f6DF31201aF55",
      Mint = "2500",
      Recipient = "JyQiTvqKIXZczY57PWOnhELUBIIKc56xWAbcM2_MXrk"
    }
  }
  # call clearMint()
  Apus@aos-2.0.1[Inbox:18]> Deposits:clearMint()
  # check again. Return empty table
  Apus@aos-2.0.1[Inbox:18]> Deposits:getToAllocateUsers()
  {  }
  ```

### Allocator

- **Allocator:compute(deposits, reward)**
  This function will calculate reward for each object in deposits list. The reward will be allocated according to their mint.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> Allocator:compute({{ User = "0x0d386297c95C7e48db734E3Eb2F476CD73f92E59", Mint = "1000000000000", Recipient = "" },{ User = "0xdA4Ef9B6d55176ab0760b8fe90152c699C91D16e", Mint = "2000000000000", Recipient = "" },{ User = "0xd0265Aa8A1b3b409F061F2AE4f39Cdbf1BA3A37a", Mint = "3000000000000", Recipient = "" }}, "100000")
  {
    {
      Reward = "16667",
      User = "0x0d386297c95C7e48db734E3Eb2F476CD73f92E59",
      Mint = "1000000000000",
      Recipient = ""
    },
    {
      Reward = "33333",
      User = "0xdA4Ef9B6d55176ab0760b8fe90152c699C91D16e",
      Mint = "2000000000000",
      Recipient = ""
    },
    {
      Reward = "50000",
      User = "0xd0265Aa8A1b3b409F061F2AE4f39Cdbf1BA3A37a",
      Mint = "3000000000000",
      Recipient = ""
    }
  }
  ```

### Distributor

- **Distributor.bindingWallet(wallet, recipient)**
  This function will set recipient for the record with user equals to wallet.
  ```shell
  # get the record first.
  Apus@aos-2.0.1[Inbox:18]> Deposits:getByUser("0xd0265Aa8A1b3b409F061F2AE4f39Cdbf1BA3A37a")
  {
    User = "0xd0265Aa8A1b3b409F061F2AE4f39Cdbf1BA3A37a",
    Mint = "0",
    Recipient = ""
  }
  # binding recipient for the user.
  Apus@aos-2.0.1[Inbox:18]> Distributor.bindingWallet("0xd0265Aa8A1b3b409F061F2AE4f39Cdbf1BA3A37a", "aa")
  # check if it works
  Apus@aos-2.0.1[Inbox:18]> Deposits:getByUser("0xd0265Aa8A1b3b409F061F2AE4f39Cdbf1BA3A37a")
  {
    User = "0xd0265Aa8A1b3b409F061F2AE4f39Cdbf1BA3A37a",
    Mint = "0",
    Recipient = "aa"
  }
  ```

- **Distributor.getWallet(wallet)**
  Return the recipient for the target user.
  ```shell
  # fetch the record first
  Apus@aos-2.0.1[Inbox:18]> Deposits:getByUser("0x8f3D0284183aBdBe3345C8cE08Ec81413e82f38F")
  {
    User = "0x8f3D0284183aBdBe3345C8cE08Ec81413e82f38F",
    Mint = "0",
    Recipient = "lpJ5Edz_8DbNnVDL0XdbsY9vCOs45NACzfI4jvo4Ba8"
  }
  # get the wallet, check if the return value is the recipient.
  Apus@aos-2.0.1[Inbox:18]> Distributor.getWallet("0x8f3D0284183aBdBe3345C8cE08Ec81413e82f38F")
  lpJ5Edz_8DbNnVDL0XdbsY9vCOs45NACzfI4jvo4Ba8
  ```

### Mint
- **MINT_CAPACITY**
  Return the capacity of the total mint schedule.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> MINT_CAPACITY
  1000000000000000000000
  ```

- **APUS_MINT_PCT_1**
  Return the mint percent at the first stage.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> APUS_MINT_PCT_1
  19421654225
  ```

- **APUS_MINT_PCT_2**
  Return the mint percent at the second stage.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> APUS_MINT_PCT_2
  16473367976
  ```

- **APUS_MINT_UNIT**
  Return the mint base.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> APUS_MINT_UNIT
  10000000000000000
  ```
- **INTERVALS_PER_YEAR**
  Return the intervals per year.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> INTERVALS_PER_YEAR
  105192.0
  ```

- **DAYS_PER_MONTH**
  Return the constant days of per month.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> DAYS_PER_MONTH
  30.4375
  ```

- **INTERVALS_PER_MONTH**
  Return the intervals per month.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> INTERVALS_PER_MONTH
  8766
  ```

- **MintedSupply**
  Return the minted supply.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> MintedSupply
  80509095358650411831
  ```

- **MintTimes**
  Return the minted times.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> MintTimes
  286
  ```

- **MINT_COOL_DOWN**
  Return the cooldown seconds of mint.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> MINT_COOL_DOWN
  300
  ```

- **LastMintTime**
  Return the last mint time.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> LastMintTime
  1733854022
  ```

- **MODE**
  Return the current mode (ON / OFF)
  ```shell
  Apus@aos-2.0.1[Inbox:18]> MODE
  on
  ```

- **Mint.batchUpdate(mintReportList)**
  Update the rewards table according to the mint report.
  ```shell
  # no users to allocate at first
  Apus@aos-2.0.1[Inbox:18]> Deposits:getToAllocateUsers()
  {  }
  # batch update for the users in table.
  Apus@aos-2.0.1[Inbox:18]> Mint.batchUpdate({{User = "0x8f3D0284183aBdBe3345C8cE08Ec81413e82f38F", Mint = "22"}, {User = "0x7300782D46E385B1D0B4e831D48c4224F502ECb9", Mint = "11"}, {User="0xEFb8a39cDcCC482EA0c92450BD0f6DF31201aF55", Mint = "33"}})
  OK
  # check again if it works
  Apus@aos-2.0.1[Inbox:18]> Deposits:getToAllocateUsers()
  {
    {
      User = "0x8f3D0284183aBdBe3345C8cE08Ec81413e82f38F",
      Mint = "22",
      Recipient = "lpJ5Edz_8DbNnVDL0XdbsY9vCOs45NACzfI4jvo4Ba8"
    },
    {
      User = "0x7300782D46E385B1D0B4e831D48c4224F502ECb9",
      Mint = "11",
      Recipient = "lpJ5Edz_8DbNnVDL0XdbsY9vCOs45NACzfI4jvo4Ba8"
    },
    {
      User = "0xEFb8a39cDcCC482EA0c92450BD0f6DF31201aF55",
      Mint = "33",
      Recipient = "JyQiTvqKIXZczY57PWOnhELUBIIKc56xWAbcM2_MXrk"
    }
  }
  ```

- **Mint.currentMintAmount()**
  Return the amount of apus tokens to be allocated in the coming mint cycle.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> Mint.currentMintAmount()
  1785796504653019
  ````

- **Mint.mint(msg)**
  Mint as per `msg.Timestamp`.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> require("os").time()
  1733854833674
  Apus@aos-2.0.1[Inbox:18]> Mint.mint({Timestamp = 1733854833674})
  Not cool down yet
  ```

- **Mint.mintBackUp(msg)**
  Same with `Mint.mint`
  ```shell
  Apus@aos-2.0.1[Inbox:18]> require("os").time()
  1733854833674
  Apus@aos-2.0.1[Inbox:18]> Mint.mintBackUp({Timestamp = 1733854833674})
  Not cool down yet
  ```

### Token
IsTNComing = IsTNComing or false
- **Variant**
  Return variant of the token.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> Variant
  0.0.3
  ```

- **Denomination**
  Return denomination of the token.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> Denomination
  12
  ```

- **Balances**
  Return the balances of the token.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> Balances
  {
    JyQiTvqKIXZczY57PWOnhELUBIIKc56xWAbcM2_MXrk = "173634843142989879",
    lpJ5Edz_8DbNnVDL0XdbsY9vCOs45NACzfI4jvo4Ba8 = "340817915426344622",
    YB6KR9AdVCiOOJFRyHSBFxkgyMD-WOaN0AC6LTQ1MMQ = "80000000000000000000"
  }
  ```

- **TotalSupply**
  Return the total supply of the token.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> TotalSupply
  1000000000000000000000
  ```

- **Name**
  Return the name of the token.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> Name
  Apus
  ```

- **Ticker**
  Return the ticker of the token.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> Ticker
  Apus
  ```

- **Logo**
  Return the logo address(ao address) of the token.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> Logo
  SBCCXwwecBlDqRLUjb8dYABExTJXLieawf7m2aBJ-KY
  ```

- **IsTNComing**
  Return if TN has coming.
  ```shell
  Apus@aos-2.0.1[Inbox:18]> IsTNComing
  # no return value because it is false
  Apus@aos-2.0.1[Inbox:18]> 
  ```

- **Token.info(msg)**
  Return the info of token.
  ```shell
  Apus@aos-2.0.1[Inbox:19]> Token.info({From = ao.id})
  Return Info
  New Message From YB6...MMQ: Action = Info-Response
  Apus@aos-2.0.1[Inbox:20]> Inbox[20].Tags
  {
    Data-Protocol = "ao",
    Denomination = "12",
    Action = "Info-Response",
    Logo = "SBCCXwwecBlDqRLUjb8dYABExTJXLieawf7m2aBJ-KY",
    Variant = "ao.TN.1",
    Name = "Apus",
    Type = "Message",
    Pushed-For = "kuYtSWDRf7rkqwaklbd8mQjBmxYJbK3lyiazs12Oxxc",
    From-Module = "GuzQrkf50rBUqz3uUgjOIFOL1XmW9nSNysTBC-wyiWM",
    Reference = "4291",
    From-Process = "YB6KR9AdVCiOOJFRyHSBFxkgyMD-WOaN0AC6LTQ1MMQ",
    Ticker = "Apus"
  }
  ```

- **Token.balance(msg)**
  Return the balance of target user.
  ```shell
  # check balances
  Apus@aos-2.0.1[Inbox:20]> Balances
  {
    JyQiTvqKIXZczY57PWOnhELUBIIKc56xWAbcM2_MXrk = "174825370677781914",
    lpJ5Edz_8DbNnVDL0XdbsY9vCOs45NACzfI4jvo4Ba8 = "343198970495928692",
    YB6KR9AdVCiOOJFRyHSBFxkgyMD-WOaN0AC6LTQ1MMQ = "80000000000000000000"
  }
  Apus@aos-2.0.1[Inbox:20]> Token.balance({Tags = {Recipient = "JyQiTvqKIXZczY57PWOnhELUBIIKc56xWAbcM2_MXrk"}, From = ao.id})
  New Message From YB6...MMQ: Data = 174825370677781914
  Apus@aos-2.0.1[Inbox:21]> Inbox[21].Data
  174825370677781914
  Apus@aos-2.0.1[Inbox:21]> Token.balance({Tags = {Target = "lpJ5Edz_8DbNnVDL0XdbsY9vCOs45NACzfI4jvo4Ba8"}, From = ao.id})
  New Message From YB6...MMQ: Data = 343198970495928692
  Apus@aos-2.0.1[Inbox:22]> Inbox[22].Data
  343198970495928692
  Apus@aos-2.0.1[Inbox:22]> Token.balance({From = ao.id, Tags = {}})
  New Message From YB6...MMQ: Data = 80000000000000000000
  Apus@aos-2.0.1[Inbox:23]> Inbox[23].Data
  80000000000000000000
  ```

- **Token.balances(msg)**
  Return the balances. It is forbidden.
  ```shell
  Apus@aos-2.0.1[Inbox:23]> Token.balances({From = ao.id})
  New Message From YB6...MMQ: Data = {}
  Apus@aos-2.0.1[Inbox:24]> Inbox[24].Tags
  {
    Data-Protocol = "ao",
    From-Module = "GuzQrkf50rBUqz3uUgjOIFOL1XmW9nSNysTBC-wyiWM",
    Type = "Message",
    Note = "Feature disabled",
    Pushed-For = "pOnN6B0nx56OlY_fD1Rx1_Y06Lj4M8Ti2lS62-70YcM",
    Reference = "4300",
    From-Process = "YB6KR9AdVCiOOJFRyHSBFxkgyMD-WOaN0AC6LTQ1MMQ",
    Variant = "ao.TN.1"
  }
  ```

- **Token.transfer(msg)**
  Transfer the apus token.
  ```shell
  Apus@aos-2.0.1[Inbox:24]> Token.transfer({Recipient = "target", Quantity = "1000000", From = ao.id})
  [string "aos"]:489: Cannot transfer until TN
  New Message From YB6...MMQ: Data = [string "aos"]:489:
  ```

- **Token.totalSupply(msg)**
  Get the total supply of the token.
  ```shell
  Apus@aos-2.0.1[Inbox:25]> Token.totalSupply({From = ao.id})


  Error on line 562: 

  error:
  Cannot call Total-Supply from the same process!
  This error occurred while aos was evaluating the submitted code.
  ```

- **Token.mintedSupply(msg)**
  Get the minted supply.
  ```shell
  Apus@aos-2.0.1[Inbox:25]> Token.mintedSupply({From = ao.id, reply = function() end})
  ```

- **Token.burn(msg)**
  Burn the token.
  ```shell
  Apus@aos-2.0.1[Inbox:26]> Token.burn({Quantity = "10000", From = ao.id})

  Error on line 567: 

  error:
  Cannot burn until TN
  ```