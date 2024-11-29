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
