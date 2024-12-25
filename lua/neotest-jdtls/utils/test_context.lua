local class = require('neotest-jdtls.utils.class')

---@class TestContext
---@field lookup table<string, table<string, table<string, JavaTestItem>>>
---@field project_name string
---@field test_kind TestKind
local TestContext = class()

function TestContext:_init()
	self.lookup = {}
end

---@param test_item JavaTestItem
function TestContext:append_test_item(key, test_item)
	self.lookup[test_item.id] = { key = key, value = test_item }
end

return TestContext
