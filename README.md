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
