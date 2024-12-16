local luaunit = require('libs.luaunit')
luaunit.LuaUnit:setOutputType("tap")
luaunit:setVerbosity(luaunit.VERBOSITY_VERBOSE)

local BintUtils = require('utils.bint_utils')
local bint = require('.bint')(256)
TestMintCycle = {}

Mint = nil

function TestMintCycle:setup()
  local sqlite3 = require('lsqlite3')
  MintDb = sqlite3.open_memory()
  DbAdmin = require('utils.db_admin').new(MintDb)
  Deposits = require('dal.deposits').new(DbAdmin)
  Mint = require('mint')
end

function TestMintCycle:testInitialMintScenarios()

        -- Set the initial minted supply and mint times to simulate the initial state.
    MintedSupply = "80000000000000000000" -- Initial minted supply.
    MintTimes = 1 -- This implies that we are just starting from the first mint cycle.
    -- Test the first mint
    local firstMint = Mint.currentMintAmount()
    print(string.format("1-th Mint Amount: %s", firstMint))

    -- Assert that the first mint is not zero and thus yields some tokens.
    luaunit.assertNotEquals(firstMint, "0", "The first mint should produce some tokens.")

    -- Update the state after the first mint
    MintedSupply = BintUtils.add(MintedSupply, firstMint)
    MintTimes = MintTimes + 1

    -- Test the second mint
    local secondMint = Mint.currentMintAmount()
    print(string.format("2-th Mint Amount: %s", secondMint))
    -- Assert that the second mint also produces tokens
    luaunit.assertNotEquals(secondMint, "0", "The second mint should produce some tokens as well.")
    -- Depending on the economic model, we might expect the second mint to be smaller or follow a certain pattern
    -- If there's a halving or reduction over time, we can verify that the second mint is less than the first.
    luaunit.assertTrue(
        bint(secondMint) <= bint(firstMint),
        "The second mint amount might be expected to be less than or equal to the first, depending on the model."
    )


    -- Update the state after the second mint
    MintedSupply = BintUtils.add(MintedSupply, secondMint)
    MintTimes = MintTimes + 1

    -- Test subsequent mints (e.g., up to the 10th mint)
    local n = 10
    local mintAmounts = {}
    for i = 3, n do
        local currentMint = Mint.currentMintAmount()
        print(string.format("%d-th Mint Amount: %s", i, currentMint))
        luaunit.assertNotEquals(currentMint, "0", string.format("The %d-th mint should produce tokens.", i))
        table.insert(mintAmounts, currentMint)

        -- Update the state after the nth mint
        MintedSupply = BintUtils.add(MintedSupply, currentMint)
        MintTimes = MintTimes + 1
    end

    -- Optionally, verify that the mint amounts follow a certain trend, such as non-increasing amounts if the model suggests halving or gradually decreasing mint outputs.
    for i = 2, #mintAmounts do
        luaunit.assertTrue(
            bint(mintAmounts[i]) <= bint(mintAmounts[i-1]),
            string.format("Expecting mint amounts to be non-increasing or stable: %s vs %s", mintAmounts[i], mintAmounts[i-1])
        )
    end
end

function TestMintCycle:testSpecificMintAmounts()
    -- Initial conditions
    MintedSupply = "80000000000000000000"  -- initial minted supply
    MintTimes = 1

-- 1-th Mint Amount: 1786792188700000
-- 2-th Mint Amount: 1786788718453993
-- 3-th Mint Amount: 1786785248214727
-- 4-th Mint Amount: 1786781777982201
-- 5-th Mint Amount: 1786778307756414
-- 6-th Mint Amount: 1786774837537367
-- 7-th Mint Amount: 1786771367325060
-- 8-th Mint Amount: 1786767897119492
-- 9-th Mint Amount: 1786764426920664
-- 10-th Mint Amount: 1786760956728576

    -- Expected values for certain mint cycles
    local expectedValues = {
        [1] = "1786792188700000",
        [5] = "1786778307756414"
    }

    -- We'll simulate multiple calls to Mint.currentMintAmount()
    -- and track the minted amounts for each cycle
    local mintedValues = {}

    for i = 1, 10 do
        local amount = Mint.currentMintAmount()
        mintedValues[i] = amount
        -- Update state for next iteration
        MintedSupply = BintUtils.add(MintedSupply, amount)
        MintTimes = MintTimes + 1
    end

    -- Now we assert specific cycles match the expected values
    luaunit.assertEquals(mintedValues[1], expectedValues[1], 
        "The 1st mint amount should match the expected value.")
    luaunit.assertEquals(mintedValues[5], expectedValues[5], 
        "The 5th mint amount should match the expected value.")
end


luaunit.LuaUnit.run()
