local JunitRunner = require('neotest-jdtls.junit.runner')
local TestNGRunner = require('neotest-jdtls.testng.runner')
local project = require('neotest-jdtls.utils.project')
local TestKind = require('neotest-jdtls.types.enums').TestKind

local M = {}

---@param args neotest.RunArgs
---@return neotest.RunSpec
function M.build_spec(args)
	-- local root = args.tree:root():data() TODO multimodule
	local current_project = project.get_current_project()
	assert(current_project.test_kind ~= TestKind.None)
	local runner
	if current_project.test_kind == TestKind.TestNG then
		runner = TestNGRunner()
	else
		runner = JunitRunner()
	end
	return runner:run(args)
end

return M
