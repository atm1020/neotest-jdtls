local class = require('neotest-jdtls.utils.class')
local get_short_error_message =
	require('neotest-jdtls.junit.common').get_short_error_message
local lib = require('neotest.lib')
local async = require('neotest.async')
local TestStatus = require('neotest-jdtls.types.enums').TestStatus

---@class DynamicTestResult
---@field is_dynamic_test boolean
---@field errors string[]
---@field output string[]
local DynamicTestResult = class()
function DynamicTestResult:_init()
	self.is_dynamic_test = true
	self.status = nil
	self.errors = {}
	self.output = {}
	self.invocation_lookup = {}
end

function DynamicTestResult:append_invocation(invocation, node)
	assert(invocation)
	assert(node)

	self.invocation_lookup[invocation] = node
end

function DynamicTestResult:get_neotest_result()
	local sum = 0
	for invocation, node in pairs(self.invocation_lookup) do
		sum = sum + 1
		self:append(invocation, node)
	end
	local results_path = async.fn.tempname()

	table.insert(
		self.output,
		1,
		string.format(
			'Total invocations: %s\nSuccess: %s\nFailed: %s\n',
			sum,
			sum - #self.errors,
			#self.errors
		)
	)
	lib.files.write(results_path, table.concat(self.output, '\n'))
	return {
		status = self.status,
		output = results_path,
		errors = self.errors,
	}
end

function DynamicTestResult:append(invocation, node)
	table.insert(
		self.output,
		string.format(
			'\n----------------%s----------------',
			node.result.status or TestStatus.Passed
		)
	)
	table.insert(
		self.output,
		string.format('Invocation %s: %s', invocation, node.display_name)
	)
	table.insert(self.output, '----------------Output----------------')

	if node.result.status == TestStatus.Failed then
		local short_message = get_short_error_message(node.result)
		self.status = TestStatus.Failed
		table.insert(self.errors, { message = short_message })
		table.insert(self.output, table.concat(node.result.trace, '\n'))
	else
		if self.status == nil then
			self.status = TestStatus.Passed
		end
		table.insert(
			self.output,
			'The console output is available in the DAP console.\n'
		)
	end
end

return DynamicTestResult
