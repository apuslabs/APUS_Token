local luaunit = require('libs.luaunit')
luaunit.LuaUnit:setOutputType("tap")
luaunit:setVerbosity(luaunit.VERBOSITY_VERBOSE)

local Utils = require('utils')
local BintUtils = require('utils.bint_utils')
local bint = require('.bint')(256)
TestMint = {}

Mint = nil

Allocator = require('allocator')

Balances = { ["ADDRESS_1"] = "80000000000000000000" }

function TestMint:setup()
    local sqlite3 = require('lsqlite3')
    MintDb = sqlite3.open_memory()
    DbAdmin = require('utils.db_admin').new(MintDb)
    Deposits = require('dal.deposits').new(DbAdmin)

    Mint = require('mint')
end

-- [[
--   Track Variables
-- ]]
function TestMint:testBasic()
    luaunit.assertNotNil(MintDb)
    luaunit.assertNotNil(DbAdmin)
    luaunit.assertNotNil(Deposits)

    luaunit.assertEquals(MINT_CAPACITY, "1000000000000000000000")
    luaunit.assertEquals(ApusStatisticsProcess, "")
    -- luaunit.assertEquals(APUS_MINT_PCT_1, 194218390)
    -- luaunit.assertEquals(APUS_MINT_PCT_2, 164733613)
    luaunit.assertEquals(INTERVALS_PER_YEAR, 365.25 * 24 * 12)
    luaunit.assertEquals(DAYS_PER_MONTH, 30.4375)
    luaunit.assertEquals(INTERVALS_PER_MONTH, math.floor(DAYS_PER_MONTH * 24 * 12 + 0.5))

    luaunit.assertEquals(MintedSupply, "80000000000000000000")
    luaunit.assertEquals(MintTimes, 1)
end

-- [[
--     Test process mint reports,  these reports are filtered by the router, so all the
--   reports should belong to this process.
-- ]]
function TestMint:testInsert()
    local mintReportList = {}
    table.insert(mintReportList, {
        Mint = "403089428078",
        User = "0x6DCeB0F7Dd6bED4fF190D8cA74F67973C280f4B4",
        Recipient = "8Dty73vZSUPPRgnFtRgCa4Qa_55gOKef-PFnb57F_FQ",
        Amount = "180000000000000000000",
        ReportTo = ao.id,
        Token = "stETH"
    })

    table.insert(mintReportList, {
        Mint = "246332428270",
        User = "0xdA4Ef9B6d55176ab0760b8fe90152c699C91D16e",
        Recipient = "8Dty73vZSUPPRgnFtRgCa4Qa_55gOKef-PFnb57F_FQ",
        Amount = "110000000000000000000",
        ReportTo = ao.id,
        Token = "stETH"
    })

    table.insert(mintReportList, {
        Mint = "139490691",
        User = "0x360d26B78eECB0DC96c3fC4d99512879916b35c4",
        Recipient = "8Dty73vZSUPPRgnFtRgCa4Qa_55gOKef-PFnb57F_FQ",
        Amount = "100000000000000000000",
        ReportTo = ao.id,
        Token = "DAI"
    })

    table.insert(mintReportList, {
        Mint = "251083244",
        User = "0x0d386297c95C7e48db734E3Eb2F476CD73f92E59",
        Recipient = "8Dty73vZSUPPRgnFtRgCa4Qa_55gOKef-PFnb57F_FQ",
        Amount = "180000000000000000000",
        ReportTo = ao.id,
        Token = "DAI"
    })

    table.insert(mintReportList, {
        Mint = "240627859",
        User = "0x7300782D46E385B1D0B4e831D48c4224F502ECb9",
        Recipient = "8Dty73vZSUPPRgnFtRgCa4Qa_55gOKef-PFnb57F_FQ",
        Amount = "172504600000000000018",
        ReportTo = ao.id,
        Token = "DAI"
    })

    table.insert(mintReportList, {
        Mint = "8369441483",
        User = "0x43C68e2C3Fc96b077d19e503a609a83Cb4D0c6fA",
        Recipient = "8Dty73vZSUPPRgnFtRgCa4Qa_55gOKef-PFnb57F_FQ",
        Amount = "5999999999999999849998",
        ReportTo = ao.id,
        Token = "DAI"
    })

    Mint.batchUpdate(mintReportList)
    luaunit.assertEquals(Deposits:getByUser("0x6DCeB0F7Dd6bED4fF190D8cA74F67973C280f4B4").Mint, "403089428078")
    luaunit.assertEquals(Deposits:getByUser("0xdA4Ef9B6d55176ab0760b8fe90152c699C91D16e").Mint, "246332428270")
    luaunit.assertEquals(Deposits:getByUser("0x360d26B78eECB0DC96c3fC4d99512879916b35c4").Mint, "139490691")
    luaunit.assertEquals(Deposits:getByUser("0x0d386297c95C7e48db734E3Eb2F476CD73f92E59").Mint, "251083244")
    luaunit.assertEquals(Deposits:getByUser("0x7300782D46E385B1D0B4e831D48c4224F502ECb9").Mint, "240627859")
    luaunit.assertEquals(Deposits:getByUser("0x43C68e2C3Fc96b077d19e503a609a83Cb4D0c6fA").Mint, "8369441483")

    luaunit.assertEquals(Deposits:getByUser("0x6DCeB0F7Dd6bED4fF190D8cA74F67973C280f4B4").Recipient, "")
    luaunit.assertEquals(Deposits:getByUser("0xdA4Ef9B6d55176ab0760b8fe90152c699C91D16e").Recipient, "")
    luaunit.assertEquals(Deposits:getByUser("0x360d26B78eECB0DC96c3fC4d99512879916b35c4").Recipient, "")
    luaunit.assertEquals(Deposits:getByUser("0x0d386297c95C7e48db734E3Eb2F476CD73f92E59").Recipient, "")
    luaunit.assertEquals(Deposits:getByUser("0x7300782D46E385B1D0B4e831D48c4224F502ECb9").Recipient, "")
    luaunit.assertEquals(Deposits:getByUser("0x43C68e2C3Fc96b077d19e503a609a83Cb4D0c6fA").Recipient, "")
end

-- [[
--     Test process mint reports,  these reports are filtered by the router, so all the
--   reports should belong to this process.
-- ]]
function TestMint:testAllocateWithoutBinding()
    local mintReportList = {}

    table.insert(mintReportList, {
        Mint = "403089428078",
        User = "0x6DCeB0F7Dd6bED4fF190D8cA74F67973C280f4B4",
        Recipient = "8Dty73vZSUPPRgnFtRgCa4Qa_55gOKef-PFnb57F_FQ",
        Amount = "180000000000000000000",
        ReportTo = ao.id,
        Token = "stETH"
    })

    table.insert(mintReportList, {
        Mint = "246332428270",
        User = "0xdA4Ef9B6d55176ab0760b8fe90152c699C91D16e",
        Recipient = "8Dty73vZSUPPRgnFtRgCa4Qa_55gOKef-PFnb57F_FQ",
        Amount = "110000000000000000000",
        ReportTo = ao.id,
        Token = "stETH"
    })

    table.insert(mintReportList, {
        Mint = "139490691",
        User = "0x360d26B78eECB0DC96c3fC4d99512879916b35c4",
        Recipient = "8Dty73vZSUPPRgnFtRgCa4Qa_55gOKef-PFnb57F_FQ",
        Amount = "100000000000000000000",
        ReportTo = ao.id,
        Token = "DAI"
    })

    table.insert(mintReportList, {
        Mint = "251083244",
        User = "0x0d386297c95C7e48db734E3Eb2F476CD73f92E59",
        Recipient = "8Dty73vZSUPPRgnFtRgCa4Qa_55gOKef-PFnb57F_FQ",
        Amount = "180000000000000000000",
        ReportTo = ao.id,
        Token = "DAI"
    })

    table.insert(mintReportList, {
        Mint = "240627859",
        User = "0x7300782D46E385B1D0B4e831D48c4224F502ECb9",
        Recipient = "8Dty73vZSUPPRgnFtRgCa4Qa_55gOKef-PFnb57F_FQ",
        Amount = "172504600000000000018",
        ReportTo = ao.id,
        Token = "DAI"
    })

    table.insert(mintReportList, {
        Mint = "8369441483",
        User = "0x43C68e2C3Fc96b077d19e503a609a83Cb4D0c6fA",
        Recipient = "8Dty73vZSUPPRgnFtRgCa4Qa_55gOKef-PFnb57F_FQ",
        Amount = "5999999999999999849998",
        ReportTo = ao.id,
        Token = "DAI"
    })

    Mint.batchUpdate(mintReportList)

    luaunit.assertEquals(Deposits:getByUser("0x6DCeB0F7Dd6bED4fF190D8cA74F67973C280f4B4").Mint, "403089428078")
    luaunit.assertEquals(Deposits:getByUser("0xdA4Ef9B6d55176ab0760b8fe90152c699C91D16e").Mint, "246332428270")
    luaunit.assertEquals(Deposits:getByUser("0x360d26B78eECB0DC96c3fC4d99512879916b35c4").Mint, "139490691")
    luaunit.assertEquals(Deposits:getByUser("0x0d386297c95C7e48db734E3Eb2F476CD73f92E59").Mint, "251083244")
    luaunit.assertEquals(Deposits:getByUser("0x7300782D46E385B1D0B4e831D48c4224F502ECb9").Mint, "240627859")
    luaunit.assertEquals(Deposits:getByUser("0x43C68e2C3Fc96b077d19e503a609a83Cb4D0c6fA").Mint, "8369441483")

    luaunit.assertEquals(Deposits:getByUser("0x6DCeB0F7Dd6bED4fF190D8cA74F67973C280f4B4").Recipient, "")
    luaunit.assertEquals(Deposits:getByUser("0xdA4Ef9B6d55176ab0760b8fe90152c699C91D16e").Recipient, "")
    luaunit.assertEquals(Deposits:getByUser("0x360d26B78eECB0DC96c3fC4d99512879916b35c4").Recipient, "")
    luaunit.assertEquals(Deposits:getByUser("0x0d386297c95C7e48db734E3Eb2F476CD73f92E59").Recipient, "")
    luaunit.assertEquals(Deposits:getByUser("0x7300782D46E385B1D0B4e831D48c4224F502ECb9").Recipient, "")
    luaunit.assertEquals(Deposits:getByUser("0x43C68e2C3Fc96b077d19e503a609a83Cb4D0c6fA").Recipient, "")

    local beforeSupply = MintedSupply
    Mint.mint()
    local afterSupply = MintedSupply
    luaunit.assertEquals(BintUtils.subtract(afterSupply, beforeSupply), "0")
    luaunit.assertEquals(Deposits:getByUser("0x6DCeB0F7Dd6bED4fF190D8cA74F67973C280f4B4").Mint, "0")
    luaunit.assertEquals(Deposits:getByUser("0xdA4Ef9B6d55176ab0760b8fe90152c699C91D16e").Mint, "0")
    luaunit.assertEquals(Deposits:getByUser("0x360d26B78eECB0DC96c3fC4d99512879916b35c4").Mint, "0")
    luaunit.assertEquals(Deposits:getByUser("0x0d386297c95C7e48db734E3Eb2F476CD73f92E59").Mint, "0")
    luaunit.assertEquals(Deposits:getByUser("0x7300782D46E385B1D0B4e831D48c4224F502ECb9").Mint, "0")
    luaunit.assertEquals(Deposits:getByUser("0x43C68e2C3Fc96b077d19e503a609a83Cb4D0c6fA").Mint, "0")
end

-- [[
--     Test process mint reports,  these reports are filtered by the router, so all the
--   reports should belong to this process.
-- ]]
function TestMint:testAllocateWithUsersBinded()
    local mintReportList = {}

    table.insert(mintReportList, {
        Mint = "403089428078",
        User = "0x6DCeB0F7Dd6bED4fF190D8cA74F67973C280f4B4",
        Recipient = "8Dty73vZSUPPRgnFtRgCa4Qa_55gOKef-PFnb57F_FQ",
        Amount = "180000000000000000000",
        ReportTo = ao.id,
        Token = "stETH"
    })

    table.insert(mintReportList, {
        Mint = "246332428270",
        User = "0xdA4Ef9B6d55176ab0760b8fe90152c699C91D16e",
        Recipient = "8Dty73vZSUPPRgnFtRgCa4Qa_55gOKef-PFnb57F_FQ",
        Amount = "110000000000000000000",
        ReportTo = ao.id,
        Token = "stETH"
    })

    table.insert(mintReportList, {
        Mint = "139490691",
        User = "0x360d26B78eECB0DC96c3fC4d99512879916b35c4",
        Recipient = "8Dty73vZSUPPRgnFtRgCa4Qa_55gOKef-PFnb57F_FQ",
        Amount = "100000000000000000000",
        ReportTo = ao.id,
        Token = "DAI"
    })

    table.insert(mintReportList, {
        Mint = "251083244",
        User = "0x0d386297c95C7e48db734E3Eb2F476CD73f92E59",
        Recipient = "8Dty73vZSUPPRgnFtRgCa4Qa_55gOKef-PFnb57F_FQ",
        Amount = "180000000000000000000",
        ReportTo = ao.id,
        Token = "DAI"
    })

    table.insert(mintReportList, {
        Mint = "240627859",
        User = "0x7300782D46E385B1D0B4e831D48c4224F502ECb9",
        Recipient = "8Dty73vZSUPPRgnFtRgCa4Qa_55gOKef-PFnb57F_FQ",
        Amount = "172504600000000000018",
        ReportTo = ao.id,
        Token = "DAI"
    })

    table.insert(mintReportList, {
        Mint = "8369441483",
        User = "0x43C68e2C3Fc96b077d19e503a609a83Cb4D0c6fA",
        Recipient = "8Dty73vZSUPPRgnFtRgCa4Qa_55gOKef-PFnb57F_FQ",
        Amount = "5999999999999999849998",
        ReportTo = ao.id,
        Token = "DAI"
    })

    Mint.batchUpdate(mintReportList)
    luaunit.assertEquals(Deposits:getByUser("0x6DCeB0F7Dd6bED4fF190D8cA74F67973C280f4B4").Mint, "403089428078")
    luaunit.assertEquals(Deposits:getByUser("0xdA4Ef9B6d55176ab0760b8fe90152c699C91D16e").Mint, "246332428270")
    luaunit.assertEquals(Deposits:getByUser("0x360d26B78eECB0DC96c3fC4d99512879916b35c4").Mint, "139490691")
    luaunit.assertEquals(Deposits:getByUser("0x0d386297c95C7e48db734E3Eb2F476CD73f92E59").Mint, "251083244")
    luaunit.assertEquals(Deposits:getByUser("0x7300782D46E385B1D0B4e831D48c4224F502ECb9").Mint, "240627859")
    luaunit.assertEquals(Deposits:getByUser("0x43C68e2C3Fc96b077d19e503a609a83Cb4D0c6fA").Mint, "8369441483")

    luaunit.assertEquals(Deposits:getByUser("0x6DCeB0F7Dd6bED4fF190D8cA74F67973C280f4B4").Recipient, "")
    luaunit.assertEquals(Deposits:getByUser("0xdA4Ef9B6d55176ab0760b8fe90152c699C91D16e").Recipient, "")
    luaunit.assertEquals(Deposits:getByUser("0x360d26B78eECB0DC96c3fC4d99512879916b35c4").Recipient, "")
    luaunit.assertEquals(Deposits:getByUser("0x0d386297c95C7e48db734E3Eb2F476CD73f92E59").Recipient, "")
    luaunit.assertEquals(Deposits:getByUser("0x7300782D46E385B1D0B4e831D48c4224F502ECb9").Recipient, "")
    luaunit.assertEquals(Deposits:getByUser("0x43C68e2C3Fc96b077d19e503a609a83Cb4D0c6fA").Recipient, "")


    Deposits.dbAdmin:apply([[Update Rewards set Recipient = ? where User = ?]],
        { "FAKE_AR_ADDRESS_1", "0x6DCeB0F7Dd6bED4fF190D8cA74F67973C280f4B4" })
    Deposits.dbAdmin:apply([[Update Rewards set Recipient = ? where User = ?]],
        { "FAKE_AR_ADDRESS_2", "0xdA4Ef9B6d55176ab0760b8fe90152c699C91D16e" })
    Deposits.dbAdmin:apply([[Update Rewards set Recipient = ? where User = ?]],
        { "FAKE_AR_ADDRESS_3", "0x360d26B78eECB0DC96c3fC4d99512879916b35c4" })
    Deposits.dbAdmin:apply([[Update Rewards set Recipient = ? where User = ?]],
        { "FAKE_AR_ADDRESS_4", "0x0d386297c95C7e48db734E3Eb2F476CD73f92E59" })
    Deposits.dbAdmin:apply([[Update Rewards set Recipient = ? where User = ?]],
        { "FAKE_AR_ADDRESS_5", "0x7300782D46E385B1D0B4e831D48c4224F502ECb9" })
    Deposits.dbAdmin:apply([[Update Rewards set Recipient = ? where User = ?]],
        { "FAKE_AR_ADDRESS_6", "0x43C68e2C3Fc96b077d19e503a609a83Cb4D0c6fA" })

    -- print(Deposits:getToAllocateUsers())
    local releaseAmount = Mint.currentMintAmount()
    local beforeSupply = MintedSupply

    Mint.mint()
    luaunit.assertIsTrue(BintUtils.subtract(MintedSupply, beforeSupply) > bint(0))
    -- luaunit.assertEquals(MintedSupply, "0")
    -- luaunit.assertEquals(Deposits:getByUser("0x6DCeB0F7Dd6bED4fF190D8cA74F67973C280f4B4").Mint, "0")
    -- luaunit.assertEquals(Deposits:getByUser("0xdA4Ef9B6d55176ab0760b8fe90152c699C91D16e").Mint, "0")
    -- luaunit.assertEquals(Deposits:getByUser("0x360d26B78eECB0DC96c3fC4d99512879916b35c4").Mint, "0")
    -- luaunit.assertEquals(Deposits:getByUser("0x0d386297c95C7e48db734E3Eb2F476CD73f92E59").Mint, "0")
    -- luaunit.assertEquals(Deposits:getByUser("0x7300782D46E385B1D0B4e831D48c4224F502ECb9").Mint, "0")
    -- luaunit.assertEquals(Deposits:getByUser("0x43C68e2C3Fc96b077d19e503a609a83Cb4D0c6fA").Mint, "0")

    -- print(Balances)
end

luaunit.LuaUnit.run()
