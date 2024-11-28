local luaunit = require('luaunit')
luaunit.LuaUnit:setOutputType("tap")
luaunit:setVerbosity(luaunit.VERBOSITY_VERBOSE)

local m = require('process.math')

TestMath = {}

function TestMath:testAdd()
    luaunit.assertEquals(m.add(1,1), 2)
end

function TestMath:testMul()
    luaunit.assertEquals(m.multiply(1,2), 2)
    luaunit.assertEquals(m.multiply(1,2), 1)
end

luaunit.LuaUnit.run()