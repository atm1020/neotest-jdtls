local class = require('neotest-jdtls.utils.class')
local TestParser = require('neotest-jdtls.testng.results.result-parser')

---@class java_test.TestParserFactory
local TestParserFactory = class()

---Returns a test parser of given type
---@param args any
---@return java_test.TestParser
function TestParserFactory.get_parser(_args)
	return TestParser()
end

return TestParserFactory
