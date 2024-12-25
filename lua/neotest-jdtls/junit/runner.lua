local class = require('neotest-jdtls.utils.class')
local log = require('neotest-jdtls.utils.log')
local TestRunner = require('neotest-jdtls.utils.base_runner')
local JunitTestParser = require('neotest-jdtls.junit.result_parser')

---@class JunitRunner : BaseRunner
local JunitRunner = class(TestRunner)

function JunitRunner:_init()
	self:super()
end

--- @param launch_arguments JunitLaunchRequestArguments
--- @param is_debug boolean
--- @param executable string
--- @return table
function JunitRunner:get_dap_launcher_config(
	launch_arguments,
	is_debug,
	executable
)
	local dap_launcher_config
	dap_launcher_config =
		self.get_base_dap_launcher_config(launch_arguments, executable, {
			debug = is_debug,
			label = 'Launch All Java Tests',
		})
	dap_launcher_config.args = dap_launcher_config.args:gsub(
		'-port ([0-9]+)',
		'-port ' .. self.server:getsockname().port
	)
	log.debug('dap_launcher_config', vim.inspect(dap_launcher_config))
	return dap_launcher_config
end

function JunitRunner:get_result_parser()
	assert(self.context.test_kind, 'test_kind is nil')
	return JunitTestParser(self.context)
end
return JunitRunner
