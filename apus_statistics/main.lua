-- Import required modules
local utils = require('.utils')               -- Utility functions module
local bintUtils = require('utils.bint_utils') -- Big integer utilities
local bint = require('.bint')(256)            -- Big integer operations with 256-bit precision
local json = require('json')                  -- JSON serialization and deserialization module

-- Set the unique identifier for the APUS mint process
APUS_MINT_PROCESS = APUS_MINT_PROCESS or "wvVpl-Tg8j15lfD5VrrhyWRR1AQnoFaMMrfgMYES1jU"

-- Initialize some global variables representing cycle information, capacity, total mint count, assets, etc.
CycleInfo = CycleInfo or {}             -- Information for the current cycle
Capacity = Capacity or 1                -- Capacity of the cycle, default is 1
TotalMint = TotalMint or "0"            -- Total mint count, initialized to 0

MintedSupply = MintedSupply or "0"      -- Minted supply initialized to 0
MintCapacity = "1000000000000000000000" -- Maximum mint capacity

UserMint = UserMint or {}               -- User-specific mint data

local userMappingJson = [[
[
    {
        "User": "0x7187E4Ef2AfEC0a2972Fb7aA77bBB848581B5cD6",
        "Mint": "0",
        "Recipient": "LWtuhySg6XPEenojALErsUWiAwzQEH5P4_EQVGtMsrs"
    },
    {
        "User": "0x1Fa5Dd9038D3f45C4825EEaDA3FC7C8267345921",
        "Mint": "0",
        "Recipient": "EDetaXmIVKUg3jzsQPFZHFmVf-AGiGigUuaCxv30lGE"
    },
    {
        "User": "0xb61141e38b2f5DCaf15e82c628400F07d1bb2FCD",
        "Mint": "0",
        "Recipient": "6fpt98wMlpt1Q1C6-xdNI0qqOGbbjhLt5zl0NFNsSHE"
    },
    {
        "User": "0x8CE6C0658025062Cc5F11e7a59c8C73813F11f87",
        "Mint": "0",
        "Recipient": "0RWuHL1469WYh146-x-5IKtes0WQweqv8d9OehyxFKw"
    },
    {
        "User": "0x71CDe6E97286848064Df6c2D5339A1B01A8B0036",
        "Mint": "0",
        "Recipient": "TBII5416lhAOttAtKiIgsUAEAiIQ3XU8VqwHAUpCZK4"
    },
    {
        "User": "0x7Ea5FBB5C8f050F182A4ab11e59E5C1c3590923F",
        "Mint": "0",
        "Recipient": "RFAFWycQRBDMNmqrYr19Lyuf2XNSgaSAouCXCMMGDH8"
    },
    {
        "User": "0x6635128C7b56076deF7Ad49b4f4179E88D421c82",
        "Mint": "0",
        "Recipient": "RFAFWycQRBDMNmqrYr19Lyuf2XNSgaSAouCXCMMGDH8"
    },
    {
        "User": "0x180C22100b1023649a01190785f886dB7CcA6aC7",
        "Mint": "0",
        "Recipient": "bp3x7EDekNipUCy1svRfkCXtlD6PsHnBYOVisBeYEIM"
    },
    {
        "User": "0x3F870610480C843b33938c640288ca4Ba5Df0D4e",
        "Mint": "0",
        "Recipient": "7dh9E0stoefHclJnF-2gBJhbdFve9oMIDUrPmW3XEew"
    },
    {
        "User": "0x313ff40b3b90ed90D0DAc823033d3baC67151B02",
        "Mint": "0",
        "Recipient": "sQ32BruFcrHMjfnr9To0X63WkRq7k-5NWNC865OwX8g"
    },
    {
        "User": "0x6Cb8f8ca8B181478DE592bAa005378F5C82cbBb9",
        "Mint": "0",
        "Recipient": "BwlVTLSU9ZTNz40OYouotsmArcp8FD6i7cUOSnpLrss"
    },
    {
        "User": "0x81b24791bC6c6713aDf55c4f135f13639e92E5Ae",
        "Mint": "0",
        "Recipient": "uyIBP93INBrIeP4H8QeqGC3l0eiYo7VCibHZlVYxizA"
    },
    {
        "User": "0xfEbcDd5DE619F7CCFfA928D9Face308CC9bf306B",
        "Mint": "0",
        "Recipient": "EvbC_B6-dPpy6QukachB7-i-UET77UEBNhqbYafnUTY"
    },
    {
        "User": "0x3f42da5562e9A37447e17313D0457B26A30cF77a",
        "Mint": "0",
        "Recipient": "yRYVkO91wXujs1SH0KZhvxTo1FC6WfTl8txPqunL6dI"
    },
    {
        "User": "0x4f646C29557dD1f5f9dDaf09B9166a154AE4E274",
        "Mint": "0",
        "Recipient": "O94QpUJ4oZ8gXlAJMV_xcigO9VyD3Kgf_wI7hTo6SGM"
    },
    {
        "User": "0x316Aef25576cBDCc95629c4e3b36B354A620A383",
        "Mint": "0",
        "Recipient": "cDa2e30IqCsM9nzFtwKcj1pMq0nIqKWWsAQlA6JSSf0"
    },
    {
        "User": "0x4ec2DcdFb3c165dA62DD1367cB42fe7551524984",
        "Mint": "0",
        "Recipient": "CMbDunV-bJf4YKfBzUYe9bavPzj81S3Zoin1DyoSJWY"
    },
    {
        "User": "0xB84753472618cfD1cccec5B5f1978c74C702a538",
        "Mint": "0",
        "Recipient": "zUX_R1z7pjEKo4KwvYSnfL4nH9J8_b2G_bGal1xM2Eo"
    },
    {
        "User": "0x89Bb1F44cE9E2D2a895F7Cf3bB88F1b3887144ff",
        "Mint": "0",
        "Recipient": "TXB_tjvBcru_NpJXm2nf1Zgm39p_mbw62z6yBX-oDmc"
    },
    {
        "User": "0x08e0097298ac59890cAb1B62487D4803F06dB284",
        "Mint": "0",
        "Recipient": "cjnNO4wraJdTCM4ANTdmCnOnBroT-0MPzKjEIzETTe0"
    },
    {
        "User": "0xA9C58107A1DD555776432366ABeDFA81a8eBF057",
        "Mint": "0",
        "Recipient": "WET0VMCpQR09T6iu5k90BcNDL85YOzOaoHv2hpJaZb0"
    },
    {
        "User": "0x32EED93105C987a0B1d12Be810c3F10d46642525",
        "Mint": "0",
        "Recipient": "QbvMF9JxaiRlUrY_ZiuoEQwZYZ8GK0Aughfh4pR903Q"
    },
    {
        "User": "0x057F5E324c45CD09C2161B3BA32c0f86780127a2",
        "Mint": "0",
        "Recipient": "Mgqpo-IvaGcULkqVVG7bNOdaZJoZQVRFfeqcUPOvF4c"
    },
    {
        "User": "0x50EB1dbdBed83d013a44315e2163b732541cd83f",
        "Mint": "0",
        "Recipient": "shUfg1ovwx0J-5y6A4HUOWJ485XHBZXoLe4vS2iOurU"
    },
    {
        "User": "0x7300782D46E385B1D0B4e831D48c4224F502ECb9",
        "Mint": "0",
        "Recipient": "lpJ5Edz_8DbNnVDL0XdbsY9vCOs45NACzfI4jvo4Ba8"
    },
    {
        "User": "0xD3b6dA66F611504A5C59022bc6cfdbd7850d00Be",
        "Mint": "0",
        "Recipient": "EDetaXmIVKUg3jzsQPFZHFmVf-AGiGigUuaCxv30lGE"
    },
    {
        "User": "0x4623021cf7c485bc1e4859519BC84D8a57a175C4",
        "Mint": "0",
        "Recipient": "zpPsZLMe49erqeMRCts8Q8Ij688UD8aunTbPW-wgsHY"
    },
    {
        "User": "0xcBfBD02ceD5740F6433180f952BBD722f1bcA8Bb",
        "Mint": "0",
        "Recipient": "cyqM8lOm7c3phfUvHn8ESj4HtsCBMr9fHKGme6UvvI4"
    },
    {
        "User": "0x233cE14b94b9835ca63CA971eBA2947E0A87EbEC",
        "Mint": "0",
        "Recipient": "rRyhNNFj4WI7ud_Q3ntryGi4cxNMfthrv0c-vbRwgQ8"
    },
    {
        "User": "0x08ECc0fA3E6feD5bD68F8842f5CCA19CF89EB735",
        "Mint": "0",
        "Recipient": "jubBjRqn0MaiziS6wIPhu7_JBxotJCjOJfKCsnwmtSI"
    },
    {
        "User": "0x342099e60aF415f761899CBA5F323a2D0B1d6357",
        "Mint": "0",
        "Recipient": "pNT5esHnPYMPh05h_m6zaQJoUnkPOSf_Mr_5jBQIIeE"
    },
    {
        "User": "0xbdA2bE1DF655181b62061b7fb9378bfE6b92D179",
        "Mint": "0",
        "Recipient": "Qsz1YOwy02TSV5eiQiNPFieEHLtPr4TryBGo2fo4lqU"
    },
    {
        "User": "0x42982dAfD5577DB35255bB1Dab0B288464844de1",
        "Mint": "0",
        "Recipient": "O9npHdWlPdUIlzTibTNPy36zoM_At2qZcUzycub6b9w"
    },
    {
        "User": "0x3d830d759cAD45eA153Bd6d2d0151b03ec5DbE69",
        "Mint": "0",
        "Recipient": "P9zb_vA1wQYLQFXvWwQ5It32h2OHnwM8AbC2Sd1wCyk"
    },
    {
        "User": "0x8813C1d5ea20342712822A1479A43bD47055C1ad",
        "Mint": "0",
        "Recipient": "FcfEMz69HsKBYtDOp0miKj5WjQ-UztyQwJqfSAffrSY"
    },
    {
        "User": "0x850dE895dAedb6fC2A02c55026826D188FC09922",
        "Mint": "0",
        "Recipient": "pIWx7GBmN7HuBM2Qyplxwpt0uiw59TC1RyL1XZrHcLY"
    },
    {
        "User": "0x59c249c7da6a815Ded545FC6c199794bFDeB2FD3",
        "Mint": "0",
        "Recipient": "iHcRPW6iSlQprUaoy9ibV9-hpIEpka_W01v4DY1ZUio"
    },
    {
        "User": "0x921aB54679D932870E29Bd378CCe6b46C3513Fb6",
        "Mint": "0",
        "Recipient": "9N7hGkrEo7ZTgg77E75FXZnogvPEm3h6ON3KnmAo6E4"
    },
    {
        "User": "0x6F25068753B8E1436e1a4FA2b7B540F75C20709E",
        "Mint": "0",
        "Recipient": "4ikSV08KsudrlNCTed8JxqGv7YjLsICJoPJuK77pquU"
    },
    {
        "User": "0x96794AbBCE11c4Af92d0FEf71aA861CDA7c9c0A3",
        "Mint": "0",
        "Recipient": "Jyf68oNLtdtlRfj1BKHCd7pQeA42_GwTnl8ZPkb2sUg"
    },
    {
        "User": "0xAd437dacDe2c57afA1e722D811F168B728130DF5",
        "Mint": "0",
        "Recipient": "BArocR03-eneHUDNq2BM0GrTQmYW-WN8L2z9I8rqs_A"
    },
    {
        "User": "0x1B59237D0cFF7b879f3A7C5045d30Ba3E9518D3F",
        "Mint": "0",
        "Recipient": "et4qKS7uf3IcT5CpgPUG95VIg4UpX0lQNkZae0mmpvk"
    },
    {
        "User": "0xf805f83E7D93AcEEea225Ea65b35b14417Ed6CFB",
        "Mint": "0",
        "Recipient": "fK6tkB2gfnxAaRhCghuO2Rm1wgaKcdRDClES0u_-jaE"
    },
    {
        "User": "0x80Feb7775a6B14617B2eDEAcc84c26bbFD26b046",
        "Mint": "0",
        "Recipient": "QqDnOBCTFmxp0s9Ax4Lq_RTY5lQYkSe2u3qVVHUMdwA"
    },
    {
        "User": "0x85813D02FC225d78f6c85A29D639fDC4d056231B",
        "Mint": "0",
        "Recipient": "YV2RFZHo-5s9q26wzC0aWvUuXnmVfNrO8Ish0dfbuzM"
    },
    {
        "User": "0x2A2A64ff0a51257fE4115a3cC1bf94687F13223d",
        "Mint": "0",
        "Recipient": "OsFW-F7vIHZC6Qm5uhaIUiW1DEHlQb38ebTgVdAlBYQ"
    },
    {
        "User": "0xd95804ddFc0F3F619A310BfC5B1FEd7eBe5fe50B",
        "Mint": "0",
        "Recipient": "oxl9OQNEOMZ4OEPv060BmO7555R3vlsqFk6aNNEQvvM"
    },
    {
        "User": "0xC2cAd53601c4419018b75C37D13C952E2A1C11fe",
        "Mint": "0",
        "Recipient": "K95TJDJwoqmLdlt4tWuN2TXlDoargI9Q2vAU4Orn0ZQ"
    },
    {
        "User": "0x8BFFe2EE168E1d670Db4fa813211B0638CdC2eB5",
        "Mint": "0",
        "Recipient": "T244ZlE04GSjLnobucmWt0wyR2VOLZyiYBUCC5kRFFg"
    },
    {
        "User": "0x4EBCc6Eb07a72aAfCc550dF49C3c358F7830672D",
        "Mint": "0",
        "Recipient": "NV7S-JKevhX-mSW-ix0EWwZXMl3GXsfesHPB-4Od1vE"
    },
    {
        "User": "0xF84204750Bff81C45383f56F63eD1D7747100c06",
        "Mint": "0",
        "Recipient": "tOpQf6GGb3Kt-iieneUwAXGfmxMhYiE9GNKWDq_wFnQ"
    },
    {
        "User": "0x42Ae6A7F5bA9999A872C6de1f223f11C5C51A156",
        "Mint": "0",
        "Recipient": "r69HswS_Nq7rddCmcaLFKnZwEnZNaylnMmdtyxlkKok"
    },
    {
        "User": "0x0ee236934d57D201b9D5bc1830f3B8E6aB121C7e",
        "Mint": "0",
        "Recipient": "45OBSIK2zsHLaw1Wr2nGtPD58mva5lJpnrjRFVub-ME"
    },
    {
        "User": "0xD6E514F54367B9204055f909a1cDb0682111b966",
        "Mint": "0",
        "Recipient": "MFUppSYMlWaNTZM3amEYXHqebv3LCB9XmTkJSAgD6Pw"
    },
    {
        "User": "0x6aA4Ee481f4bf418c1c2c862f5c2413C04D47992",
        "Mint": "0",
        "Recipient": "RiJXHCXLB3wVwPvkynvWP6KDjq6D7UbsLoVH8XlJb5I"
    },
    {
        "User": "0x998E8f6F7e06967a404EeEB38a55FA0709e3728D",
        "Mint": "0",
        "Recipient": "rC04rYnMiqTBAWBz0ac8MxDfgWrxgyaC6c1W1WDEMqg"
    },
    {
        "User": "0x4575C2359882836526c522De74c5CFf45cF109F6",
        "Mint": "0",
        "Recipient": "5eF6MgtWuL7h5NHpqp8rfd9NM9_ebH3-jmn8YPvDAEQ"
    },
    {
        "User": "0x30A6BcaD74534fa05Fb039D36B80d36d92a99628",
        "Mint": "0",
        "Recipient": "l9kcSM8ooA1BloFvCotROA6nL__4UWtGV7sfqcN6hFI"
    },
    {
        "User": "0x8e2beE1BF31a67E8d6423CFeDF8578fe051b1AeD",
        "Mint": "0",
        "Recipient": "p61YoX8Yyyx28ZTNoKJ9XLcgYjTLxDISEg8Vx5h-dsk"
    },
    {
        "User": "0x9C857cd5f8326699Ac90d684fe74695861716938",
        "Mint": "0",
        "Recipient": "MJvWcgZySAPiLz_1QNPdPeEiignV1KUK3MPTsKdAKWM"
    },
    {
        "User": "0xb01Eaede24ad33b820f8c1bD35eA9324230Ede3E",
        "Mint": "0",
        "Recipient": "y9vJYdKxt7uIkiw4O_zswbqcOWahIfPbCZvOuHRw8Bk"
    },
    {
        "User": "0xb56E85e81d3C4Aeed3cB34E64eBB5714016E447d",
        "Mint": "0",
        "Recipient": "ZWWArGHWLj66lpFEOT4i3g711pwnjs3wU2L3ios3POc"
    },
    {
        "User": "0x5Bc61A5ee2276897a3d60C4387602390Cc12e055",
        "Mint": "0",
        "Recipient": "zzbUhNoiUPQ3Tj47ihcOQc7MkCsRtNQDUxgzaMc1k9g"
    },
    {
        "User": "0x142F3c7218174973caEC8d4495b7B1296741c345",
        "Mint": "0",
        "Recipient": "-B94zssdipTvDIsSoeHgH6xxyR4afWef2xZWxmAuU4Y"
    },
    {
        "User": "0xe47BD059D18e8e2B1b242A66136CB09476577695",
        "Mint": "0",
        "Recipient": "XX4ssz8MKbXvbVXhBRl84TWDDwkkme96lMkjpL7IpXs"
    },
    {
        "User": "0xb650a743759955AA7D6f25E0991FeA06Bbb4fc21",
        "Mint": "0",
        "Recipient": "fftWZBg2g0-day-0FXpMc64YNPXHXkGEgBmtj09A6DY"
    },
    {
        "User": "0x79f616ce0652bD86F7bbf5BF0E443ed076e453c5",
        "Mint": "0",
        "Recipient": "WukWGVUJQ1bd3U--pg5u0lF6hVbuQlSnEUXf4qdwbYA"
    },
    {
        "User": "0x7096903dB68Eff856c980ACb21c8a8f06C11D951",
        "Mint": "0",
        "Recipient": "Q4HwnwtSjDbd3CNYw5ViDM2Mb2Ac7cnanoRnhLeXUz0"
    },
    {
        "User": "0xa2C14F8374Bff1EaE33356251DF91fC427590F0E",
        "Mint": "0",
        "Recipient": "8meefDed7T2z-EUpITBtXtKrXa7bDAZUdSn-uuPMBCo"
    },
    {
        "User": "0x475681F0e12606cf8f97743C1d4558C06a287840",
        "Mint": "0",
        "Recipient": "py2WD8WKTW_ryFD2GdECFll-9u0UwU38IdJuXrkODJ0"
    },
    {
        "User": "0x3d186b818e6897229CFeE292cBabd950dAC85B3a",
        "Mint": "0",
        "Recipient": "Imd9bsYMtrr3oinRvM2hqUfuzMtaZCiT0qAf08lujfI"
    },
    {
        "User": "0xB3885AA03a7Bf92E402cC0F095Ba7FC32F540981",
        "Mint": "0",
        "Recipient": "r2frn3JbPrv24sWscQLXbCH85Yy6v4hPdr62p9Ps0vM"
    },
    {
        "User": "0x8559cac2b3ae92d550bF0DF4093A9e6fCe99dE05",
        "Mint": "0",
        "Recipient": "XlHOoUiICPL1rU9JeJneNa04blvCPRVi9M1E9lqyuYI"
    },
    {
        "User": "0x0f72A28b39eE4108a35e3cF47A54f3D7a9d6d06b",
        "Mint": "0",
        "Recipient": "-0NOjxpv-9O-aK4JxxSjB-63eK-UgTP-LbVFzzwXjBY"
    },
    {
        "User": "0x8187516CCD85CB86F437f6D150e2B9F6CbeA8F07",
        "Mint": "0",
        "Recipient": "qI4pgr4C5IIe71GBBfLGnSwpIINjCNhm7mluqZhHbXY"
    },
    {
        "User": "0x5937562623dB74E37EbC378506B6AF1397498d68",
        "Mint": "0",
        "Recipient": "HcTE0gtR74DdVp4fHce7vns2kLib0ExUo_EpdDCmbHw"
    },
    {
        "User": "0x19d2398449093f270837d1b44D8CD6DdF686B3c4",
        "Mint": "0",
        "Recipient": "Yoqrk4cnv4w6fzB1BBKK5hm4yOyuKo3roRkl-Iy2Cdo"
    },
    {
        "User": "0xf748879EdBe8CcA140940788163d7bE4d2A2E46A",
        "Mint": "0",
        "Recipient": "-5DvPccFs7hE_OSLBfe4qssfUKymFdoFrYEYZti2UbI"
    },
    {
        "User": "0x4874F6Aa1D42cc8DC8b7d83aAdA07Cd447b8367E",
        "Mint": "0",
        "Recipient": "2NQZalVCac6xFyOgHpG-pG3adW5hS8PMszsfRp76L5Y"
    },
    {
        "User": "0x0C52d02897D5d82533935CFd4B1BF5824d6A3Dc2",
        "Mint": "0",
        "Recipient": "oxljmqofP9Qe5Nzk2zAk-aEynbKRbJbfxRp06RvPtJ4"
    },
    {
        "User": "0xd949a3b25424f263598249731A16d90Ff5ed4A6E",
        "Mint": "0",
        "Recipient": "OmvHf0ePcg6Kdqlt7jTh-HZRyxTv-dzB3JF-m-TStdM"
    },
    {
        "User": "0x2d3a3F51Ac7E6462a58A7eD245b893e0bd0509d3",
        "Mint": "0",
        "Recipient": "6ejaZ9uWZcpDHnQ7P9ZDd2qEamWiYIm4rCuwyPq0SuI"
    },
    {
        "User": "0xB5A8B1DF4763063224E08A2A885D056E498588e6",
        "Mint": "0",
        "Recipient": "M5OxYzIHqAIivDnK0NGklKtKMJrpMVYKM1XcDp-Cdvo"
    },
    {
        "User": "0xD17398D984624B3fd7486bE788c2b2f8e10142a2",
        "Mint": "0",
        "Recipient": "JiXiLwTXFXP0hdfL3gyIV960D4sTC1Bk_KUO1P1-jv4"
    },
    {
        "User": "0x6c3C002d8d56A886995d0817C582db34C43B6838",
        "Mint": "0",
        "Recipient": "Q29t-Fo0Wc2V-b4RIyWlxKjZEP5fAFuR1UEAv0X7ZqE"
    },
    {
        "User": "0x15FB1af725c24b92FAab4cE7f173c98625E9D10f",
        "Mint": "0",
        "Recipient": "jO4McXOM76FxrY0vnmDinVJ2BG6sDfjJWd0ot-wdpDs"
    },
    {
        "User": "0xD76098596f1d808b92A7dBc6e7147846d94cb1D5",
        "Mint": "0",
        "Recipient": "VWj03S6f6MnZGFNjTEBkKnV518KodWzOfgFi_WuDN1o"
    },
    {
        "User": "0xe8fa1Dc4d23c54C3C03fcF25EECa7E0Ff882a75e",
        "Mint": "0",
        "Recipient": "lpJ5Edz_8DbNnVDL0XdbsY9vCOs45NACzfI4jvo4Ba8"
    },
    {
        "User": "0x851618e0AC137B94589d18b954c20F946c6410d2",
        "Mint": "0",
        "Recipient": "ZZ4x0QstkyCgLPzWfLkwD2ziEXkCtbxXhTnMZL0yGvA"
    },
    {
        "User": "0xA8E71923dFc7E5075Ca5CB047Bdbec182d446C5e",
        "Mint": "0",
        "Recipient": "mUzJBP5y8vXZ9LO8Iu7e2wrbhl2IhKV5D10bNoPRKMQ"
    },
    {
        "User": "0x800c443D4fC0048D2f4a83d64CDEc93a824BE745",
        "Mint": "0",
        "Recipient": "9O99AICiHH9be-8b9-Mnn1W3XNkwlI4ph0yepYUswPA"
    },
    {
        "User": "0xCa13Af63B489c8A780055b56A80cFbCa3CC2C3BC",
        "Mint": "0",
        "Recipient": "gJppj8jsZctjesyRRgB1-_Cw72KVylDV6DCPxezmTHc"
    },
    {
        "User": "0xA2FbcEfA58D2Fa7a96838Eef4e8b76c4a6AFe73C",
        "Mint": "0",
        "Recipient": "6sRPE3la2hXA1d6mucIJ2ajR-4XxDCjte-2MnP4rEeA"
    },
    {
        "User": "0x72BcDDb6c047CcD6D55cfA38E1Ce468FdA88407f",
        "Mint": "0",
        "Recipient": "2RZuIlzsfMWFj0XyDn8wMlq_YBx_RmyPU2XteztXd_M"
    },
    {
        "User": "0x5A780948531578E39528904b56c3Af5095437A0A",
        "Mint": "0",
        "Recipient": "QoP4uuhSML8gzXuAU04hnhxVkfK5tcfU29GZUZwKGro"
    },
    {
        "User": "0x2ebbd5a37Bca00ae65fE068a385F100729Bd7Bdb",
        "Mint": "0",
        "Recipient": "OoJ8kBTnXuHHzGLQy_7Ek6scUlP7zGXu5GJU86BsvtI"
    },
    {
        "User": "0xa9f078B3b6DD6C04308f19DEF394b6D5a1B8b732",
        "Mint": "0",
        "Recipient": "Oy38O-7kZ6nXZ2M5639V0DLoyATrtlelebYNozXfwBc"
    },
    {
        "User": "0x64c8589F3b9F26833Cb37A7f75dc96e82246397a",
        "Mint": "0",
        "Recipient": "-d_4yiM4dEuOZyXBP2xlxbAAPE7S8jGpifxVOGw69m4"
    },
    {
        "User": "0xbcD2e702e8419967d197801b969BaCa93D260a7d",
        "Mint": "0",
        "Recipient": "wWq05ZZX6Jj2p9wW59oZ6lMF_KdW754zywqLa9n8INA"
    },
    {
        "User": "0xB5714084eeF0f02eFDD145DFB3Fe2e3290591D7b",
        "Mint": "0",
        "Recipient": "qwDZM6PQ55JlhQ7ctDl8ScxdwMu40_rXkHp9actXWp4"
    },
    {
        "User": "0x6d44B193B931a7818b97D923C33412753830bce7",
        "Mint": "0",
        "Recipient": "tlDC97sQ2uCgjzls1ZnWAHHk6iWO9XGLdmO59kmyygk"
    },
    {
        "User": "0x74e8F8a79750093D65684F049927e93309CCA242",
        "Mint": "0",
        "Recipient": "-5DvPccFs7hE_OSLBfe4qssfUKymFdoFrYEYZti2UbI"
    },
    {
        "User": "0x5BD511FDf28c1C873e3D508B9BB5145d5350ee7B",
        "Mint": "0",
        "Recipient": "Fx0b3swbuyJ1enSOQigECbpecaZe-hAHZzrqQEA1VsM"
    },
    {
        "User": "0xAA332Dc947074b9fE050b302F512D8BAc5d42cC9",
        "Mint": "0",
        "Recipient": "UbFkbToSBEncly_PnDrf2dcWpCbEnh5GS9_17_lof40"
    },
    {
        "User": "0x9FfF7A309Ff09d41F04f8B0ED76483Ee6C4AdDB3",
        "Mint": "0",
        "Recipient": "ORllhwVgde_UpvnW9uKEZQIKUZ9ul21G9FceivaBYwo"
    },
    {
        "User": "0x0354BD711ac7689bFA165f1B0184F48bC4d3f606",
        "Mint": "0",
        "Recipient": "00KeOFYamsTTImWd76NQNClkP9G1Rm9gMsoSovrpTE8"
    },
    {
        "User": "0x64b6eBE0A55244f09dFb1e46Fe59b74Ab94F8BE1",
        "Mint": "0",
        "Recipient": "b196UTcqMHqJyHERm_xWlB54Rx2bFB3tSPuQTrDfRF8"
    },
    {
        "User": "0xdC71e82E1150263Ad3A9b184249EeEA36F4B3A80",
        "Mint": "0",
        "Recipient": "iPDojVpsZf8SLepII3a5EtkmuGv4N6LAP-PsGcYKgRk"
    },
    {
        "User": "0xF756fE7FF4F56b227881d095b90ECa3802097506",
        "Mint": "0",
        "Recipient": "MEAsi72uc_Z8VtAdf2GC521B0HSevaSecCtxELOXaCg"
    },
    {
        "User": "0xe662d37f1D1E2e900820F7C59e9460457c5E2323",
        "Mint": "0",
        "Recipient": "cTzP_gnCAs9R1iemwanJ9xjpgIp0NQdv2TKyOCM8wZo"
    },
    {
        "User": "0x0997a0dEcC9872fcb5e4CaF446401e6Cadb931F5",
        "Mint": "0",
        "Recipient": "Ns9eapXmBka6kVXQ0nynEYo9KDKF4HlNMC2_MmbwTVs"
    },
    {
        "User": "0x9630B52B7FC5191E5D18fE8E9A93D9c2c8cc5163",
        "Mint": "0",
        "Recipient": "7CzdnKEgdU8yN1qjtN0_a2JaCkWsqgHZB1vGhBaX3AQ"
    },
    {
        "User": "0xd35D68Fe3F7Ae603d984B3b17C9dFe156B973Fd5",
        "Mint": "0",
        "Recipient": "_izWq_r55uJyHnWi-GZJUnU6BZBf3UHBnwWt26ReLzM"
    },
    {
        "User": "0x1388a3c83Bd6d184A9f849fA2A3a58326FC1694C",
        "Mint": "0",
        "Recipient": "6JBkDWwcdzwe7-8QllMqhYYgLALeVDcUdSb5vK16lG0"
    },
    {
        "User": "0xB135D40581404474Beca15Ba408E2E67A178b4cd",
        "Mint": "0",
        "Recipient": "k3sIA6kF6D1fdQxWqV6We24k4-i_rn8w6q_kIRUCVis"
    },
    {
        "User": "0x582c34536D7f4A2A5d96118D5D80Ba3000c6B5aF",
        "Mint": "0",
        "Recipient": "DrIgbODT0mXRgKbmk3Bjs2Fy418iKvlxeeRu5W_zcC0"
    },
    {
        "User": "0x44011feB42AAfA82a88921AA1E2720c408bA73a5",
        "Mint": "0",
        "Recipient": "Ymk0nbjDyBfV2pgrQixmElvLtF2Xe49RYbE2gLJiHlU"
    },
    {
        "User": "0x06Db1437F345660789C8a75105702CAb07aa62e3",
        "Mint": "0",
        "Recipient": "BC_4q2YdKHRwq3nO4H1_B82gJmI1c8t3JD7BO02rE9U"
    },
    {
        "User": "0x9E4a3B3a0BBb8f0Ab27D977446180C3436aFB9F9",
        "Mint": "0",
        "Recipient": "-5DvPccFs7hE_OSLBfe4qssfUKymFdoFrYEYZti2UbI"
    },
    {
        "User": "0x7A128b34485AB460B96B9f3Df3FE7bbD949d5219",
        "Mint": "0",
        "Recipient": "enMTr4rGpzcmno1W4RgihNfa2haOIuJoRD6OxSEvdH8"
    },
    {
        "User": "0x0D7c1212C49e47DFf9549401351F40B6C404dC43",
        "Mint": "0",
        "Recipient": "u0R9kfBfczo2h90473f3llM7Z5Ig_Te_rGS5cOyjoww"
    },
    {
        "User": "0x9B5403DC862B440d9d8D4AE15405A761dcA88fdD",
        "Mint": "0",
        "Recipient": "w1_UF_Gjzuj-pZnaE0NnAWnvsCrGaPeBE_qvwlPc0M8"
    },
    {
        "User": "0xD8c2e378c699b7E3E5F97cF4F0F46741296D8Cbf",
        "Mint": "0",
        "Recipient": "Cqb2GXPXHiEDdeWCrMD5_2tESW7lovednxZyau6C8g4"
    },
    {
        "User": "0x64D13D5316d5FDC4A25F178bB073278443c80d55",
        "Mint": "0",
        "Recipient": "SditZ5OjGTXGvqirNijuq5s1lP5m5hVP99wB6893sm4"
    },
    {
        "User": "0x1f7D425a7b0579948E1671F239bbbB1E988A4DF9",
        "Mint": "0",
        "Recipient": "e2mRK4Z4d_i6gdsuA-IQypepr94Yz1W4ANFGpKuumOs"
    },
    {
        "User": "0xbD3E5876cc7924Be16c2534B1B990A808041469C",
        "Mint": "0",
        "Recipient": "Irsg8i7CDvGaqs2qX148g5J2G_S5yq7RWdO7TV73qPY"
    },
    {
        "User": "0x28aFCDCD64E5642D13aF9d4B816B73320407270a",
        "Mint": "0",
        "Recipient": "r_nX6JkiQD12LwKE1Va23GejVjTp12YJk3FDDaFhqPA"
    },
    {
        "User": "0x71B56041FA7edFd609209a99844a08e3d3AcF601",
        "Mint": "0",
        "Recipient": "7oqF5rsBLc8MqWnrOHloVjixlbpfT7IdFqRQfyaNLOg"
    },
    {
        "User": "0x9A826c091f16E4956020B8FEE6d4832F69b34774",
        "Mint": "0",
        "Recipient": "OP2NFo-w_Z2lVU2aB8qSo9P-s7-9sWjjs8d0EEFfGoM"
    },
    {
        "User": "0xc256af132AE488FF25b8D80D459600ae3ED87d83",
        "Mint": "0",
        "Recipient": "jvwVQ-AH_mOf0MtXBdt_eMeWPxol1kAvzhK-G5kUqvw"
    },
    {
        "User": "0x11b16cfCf212EdD202d202D6afA931F2c97C1800",
        "Mint": "0",
        "Recipient": "1WcFkLMjDQj3khhLz4-xorBTQJlOOifBlsoG1Oi4hOI"
    },
    {
        "User": "0x28CdD7827A8FcebE137753B03790633aa39bdD2e",
        "Mint": "0",
        "Recipient": "ypwoKMpujm1kdQoDJF0x5XMuXggOlXrr9GaVWfz9fUw"
    },
    {
        "User": "0x309078Aee712243Aebd46F9B2A57EB41b3DB9178",
        "Mint": "0",
        "Recipient": "1ZeDruYNpcbMiWNJC2OE0yLwZ7niunTRocNNJIwkdGM"
    },
    {
        "User": "0x64658CBBebFaf1bDc9FEab1A868874a17945265b",
        "Mint": "0",
        "Recipient": "gPhAfBBVsPgcRzcc7AtaW4DYil4iAevmCtjA-B65-C0"
    },
    {
        "User": "0xfcCa2e5ed43E4A2045F7748337E1e3aff10AeB9c",
        "Mint": "0",
        "Recipient": "m02oI2EXh9I_2PMcsgfu1vUZVkmwNKC0AqS90TvDK9w"
    },
    {
        "User": "0x2120A555705483d34bC432B235DEd7894e9EB9d3",
        "Mint": "0",
        "Recipient": "W_32lND2XuJURFhca5Rf3yp7AJeYYuP19C979SvWdjo"
    },
    {
        "User": "0x4dD0e19550f2735c3317Df8868Ec9191E4927E7f",
        "Mint": "0",
        "Recipient": "yqRGaljOLb2IvKkYVa87Wdcc8m_4w6FI58Gej05gorA"
    },
    {
        "User": "0xbF2541379ffd87f1484B9D729ADC43cB3A87E083",
        "Mint": "0",
        "Recipient": "-RapJqpPYSLLDJf0sTDE3Avo_2dlb13BGXYrrrwyiI8"
    }
]
]]

-- Function to get the ETH address for a given user address
local function getUserETHAddress(userAddress)
  local userMapping = json.decode(userMappingJson)
  for _, mapping in ipairs(userMapping) do
    if string.lower(mapping.Recipient) == string.lower(userAddress) then
      return string.lower(mapping.User)
    end
  end
  -- if the user address is not found in the userMapping, return the user address
  return nil
end


-- Function to check if the mint report is from the APUS mint process
local function isMintReportFromAPUSToken(msg)
  return msg.Action == "Report.Mint" and msg.From == APUS_MINT_PROCESS
end

-- Function to calculate the total mint amount from a list of reports
local function getTotalMint(reportList)
  return utils.reduce(function(acc, value)
    return bintUtils.add(acc, value.Yield) -- Accumulate the total mint amount
  end, "0", reportList)
end

-- Function to update the user mint data based on the mint reports
local function updateUserMint(mintReports)
  local newUserMint = {}
  for _, mr in ipairs(mintReports) do
      -- Normalize the user address to lower-case for compatibility
      local userAddress = string.lower(mr.User)
      -- Add to the user's total Mint
      newUserMint[userAddress] = bintUtils.add(newUserMint[userAddress] or "0", mr.Yield)
  end
  UserMint = newUserMint
end

-- Cron job handler that periodically requests the minted supply data
Handlers.add("Cron", "Cron", function(msg)
  Send({
    Target = APUS_MINT_PROCESS,
    Action = "Minted-Supply"
  }).onReply(function(replyMsg)
    -- Update the minted supply when the reply is received
    MintedSupply = replyMsg.Data
  end)
end)

-- Handler for mint report messages (i.e., mint actions from APUS token)
Handlers.add("Report.Mint", isMintReportFromAPUSToken, function(msg)
  local status, err = pcall(function()
    if #CycleInfo >= Capacity then
      table.remove(CycleInfo, 1) -- Remove the oldest cycle if the capacity is exceeded
    end
    local mintReports = msg.Data
    print('Receive mint reports: ' .. #mintReports .. ' record(s).')

    -- Calculate total mint
    local totalMint = getTotalMint(mintReports)

    -- Update the total mint value
    if TotalMint == "0" then
      TotalMint = totalMint
    else
      TotalMint = bintUtils.toBalanceValue((bint(TotalMint) * bint(Capacity - 1) + bint(totalMint)) // bint(Capacity))
    end

    -- Update the user mint data
    updateUserMint(mintReports)

    -- Add the current cycle data to the cycle info
    table.insert(CycleInfo, {
      TotalMint = totalMint,
    })
  end)
  if err then
    print("Error: " .. err) -- Log the error if there's an issue
    return
  end
end)

-- Handler to estimate the user's APUS token based on the user's mint share
Handlers.add("User.Get-User-Estimated-Apus-Token", "User.Get-User-Estimated-Apus-Token", function(msg)
  local status, err = pcall(function()
    local targetUser = string.lower(msg.User)

    -- Get the ETH address for the given user address
    local userETH = getUserETHAddress(targetUser)
    if userETH then
      targetUser = userETH
    end

    assert(targetUser ~= nil, "Param target user not exists")

    local share = UserMint[targetUser] or "0"
    local totalShare = TotalMint

    -- APUS_MINT_PCT_1 = 19421654225 APUS_MINT_PCT_2 = 16473367976
    -- 1.678% 1.425%
    -- StartMintTime  1734513300
    -- Calculate the predicted monthly reward based on remaining mint capacity
    local pct = 1678
    if msg.Timestamp // 1000 > 1734513300 + 365.25 * 24 * 60 * 60 then
      pct = 1425
      Logger.info("APUS mint pct is 1.425%")    
    end
    local predictedMonthlyReward = bintUtils.toBalanceValue(bint(bintUtils.subtract(MintCapacity,
      MintedSupply)) * pct // 100000)
    -- Calculate the estimated reward for the user based on their share
    local res = bintUtils.toBalanceValue(bint(predictedMonthlyReward) * bint(share) // bint(totalShare))

    msg.reply({ Data = res }) -- Return the estimated result for the user
  end)
  if err ~= nil then
    print("Error: " .. err)
    return
  end
end)
