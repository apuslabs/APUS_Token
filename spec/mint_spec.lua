local luaunit = require('libs.luaunit')
luaunit.LuaUnit:setOutputType("tap")
luaunit:setVerbosity(luaunit.VERBOSITY_VERBOSE)

local Utils = require('utils')

TestToken = {}

function TestToken:setup()
    self.m = require('token')
end

function TestToken:testInfo()
    self.m.info({
        From = "lpJ5Edz_8DbNnVDL0XdbsY9vCOs45NACzfI4jvo4Ba8"
    })
    local message = Utils.getLatestMessage()
    luaunit.assertEquals(Utils.getValueFromTags(message.Tags, 'Name'), "Apus")
end

TestMain = {}

function TestMain:setup()
    require('main')
end

function TestMain:testBalance()
    print(Handlers.list)
    local response = require(".process").handle({
        From = "1",
        Target = ao.id,
        Owner = ao.id,
        Tags = {
            { name = "Action", value = "Info" },
        },
        Data = ""
    }, ao.env)
    luaunit.assertEquals(Utils.getValueFromTags(response.Messages[1].Tags, 'Name'), "Apus")
end

luaunit.LuaUnit.run()