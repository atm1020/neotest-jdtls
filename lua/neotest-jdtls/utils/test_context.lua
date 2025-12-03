local class = require('neotest-jdtls.utils.class')
local log = require('neotest-jdtls.utils.log')

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

	local id = test_item.id:gsub("[<>%s]", "")
	log.debug(
		"Cleaned test item id: ",
		id,
		" -> ",
		test_item.id
	)
	self.lookup[id] = { key = key, value = test_item }
end

return TestContext
