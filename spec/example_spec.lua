local luaunit = require('libs.luaunit')
luaunit.LuaUnit:setOutputType("tap")
luaunit:setVerbosity(luaunit.VERBOSITY_VERBOSE)

TestExample = {}

function TestExample:testBasic()
    luaunit.assertEquals(1 + 1, 2)
    luaunit.assertEquals({1, 2}, {1, 2})
    luaunit.assertNotEquals(1 + 1, 3)
    luaunit.assertTrue(1 < 2)
    luaunit.assertFalse(1 > 2)
end

function TestExample:testTable()
    luaunit.assertItemsEquals({1, 2}, {2, 1}) -- 顺序无关
end

function TestExample:testType()
    luaunit.assertIsNil(nil)
    luaunit.assertNotNil("hello")
    luaunit.assertIsNumber(42)
    luaunit.assertIsString("hello")
    luaunit.assertIsFunction(function() end)
end

function TestExample:testError()
    luaunit.assertError(function() error("some error") end)
    luaunit.assertErrorMsgContains("some error", function() error("some error occurred") end)
end

function TestExample:testString()
    luaunit.assertStrContains("hello world", "world")
    luaunit.assertStrIContains("hello world", "WORLD")
    luaunit.assertNotStrContains("hello world", "moon")
    luaunit.assertNotStrIContains("hello world", "MOON")
    luaunit.assertStrMatches("hello world", "hello %w+")
end

function TestExample:testFloat()
    luaunit.assertAlmostEquals(3.14, 3.14159, 0.01)
end

function setup()
    print("Before each test")
end

function TestExample:setup()
    print("Setup for TestExample is called")
    self.value = 42 -- 初始化状态
end

function teardown()
    print("After each test")
end

function TestExample:testSkip()
    if true then
        luaunit.skip("Skipping this test")
    end
end

luaunit.LuaUnit.run()