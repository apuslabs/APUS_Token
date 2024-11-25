-- spec/sepc/mint/mint_spec.lua
package.path = "../apus_token/?.lua;" .. package.path
print(package.path)

local function set_alias(alias, module)
    package.preload[alias] = function()
        return require(module)
    end
end

set_alias(".bint", "lib/bint")
set_alias("bint", "lib/bint")
set_alias("json", "cjson")

local Mint = require("mint")

describe("Mint", function()
  describe("test111", function ()
    it("test", function ()
      Mint.simulateRelease({futureTime = os.time() + 3600 * 366 * 24 * 30})
    end)
  end)
end)