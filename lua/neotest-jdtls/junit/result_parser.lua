local class = require('neotest-jdtls.utils.class')
local log = require('neotest-jdtls.utils.log')
local async = require('neotest.async')
local lib = require('neotest.lib')
local TestStatus = require('neotest-jdtls.types.enums').TestStatus
local TestKind = require('neotest-jdtls.types.enums').TestKind
local DynamicTestResult = require('neotest-jdtls.junit.dynamic_test_result')
local get_short_error_message =
	require('neotest-jdtls.junit.common').get_short_error_message
local BaseParser = require('neotest-jdtls.utils.base_parser')

local default_passed_test_output =
	'The console output is available in the DAP console.'
---@type string|nil
local default_passed_test_output_path = nil

---@enum java_test.TestExecStatus
local TestExecStatus = {
	Started = 'started',
	Ended = 'ended',
}

---@enum MessageId
local MessageId = {
	TestTree = '%TSTTREE',
	TestStart = '%TESTS',
	TestEnd = '%TESTE',
	TestFailed = '%FAILED',
	TestError = '%ERROR',
	ExpectStart = '%EXPECTS',
	ExpectEnd = '%EXPECTE',
	ActualStart = '%ACTUALS',
	ActualEnd = '%ACTUALE',
	TraceStart = '%TRACES',
	TraceEnd = '%TRACEE',
	IGNORE_TEST_PREFIX = '@Ignore: ',
	ASSUMPTION_FAILED_TEST_PREFIX = '@AssumptionFailure: ',
}

local JUnitTestPart = {
	CLASS = 'class:',
	NESTED_CLASS = 'nested-class:',
	METHOD = 'method:',
	TEST_FACTORY = 'test-factory:',
	-- Property id is for jqwik
	PROPERTY = 'property:',
	TEST_TEMPLATE = 'test-template:',
	TEST_TEMPLATE_INVOCATION = 'test-template-invocation:',
	DYNAMIC_CONTAINER = 'dynamic-container:',
	DYNAMIC_TEST = 'dynamic-test:',
}

local array_lookup = {
	['%5BB'] = 'byte[]',
	['%5BS'] = 'short[]',
	['%5BI'] = 'int[]',
	['%5BJ'] = 'long[]',
	['%5BF'] = 'float[]',
	['%5BD'] = 'double[]',
	['%5BC'] = 'char[]',
	['%5BZ'] = 'boolean[]',
}

---@class java_test.JunitTestParser : BaseParser
---@field private test_details java_test.TestResults[]
local JunitTestParser = class(BaseParser)

---@param context TestContext
function JunitTestParser:_init(context)
	-- self:super()
	self.context = context
	self.test_details = {}
	self.lookup = {}
	self.results = {}
end

---@private
JunitTestParser.node_parsers = {
	[MessageId.TestTree] = 'parse_test_tree',
	[MessageId.TestStart] = 'parse_test_start',
	[MessageId.TestEnd] = 'parse_test_end',
	[MessageId.TestFailed] = 'parse_test_failed',
	[MessageId.TestError] = 'parse_test_failed',
}

---@private
JunitTestParser.strtobool = {
	['true'] = true,
	['false'] = false,
}

---@private
function JunitTestParser._get_default_passed_test_output_path()
	if not default_passed_test_output_path then
		default_passed_test_output_path = async.fn.tempname()
		lib.files.write(default_passed_test_output_path, default_passed_test_output)
	end
	return default_passed_test_output_path
end

---@private
function JunitTestParser._split(str)
	local result = {}
	local current_match = {}
	local escape = false
	for i = 1, #str do
		local c = str:sub(i, i)
		if escape then
			table.insert(current_match, c)
			escape = false
		elseif c == '\\' then
			table.insert(current_match, c)
			escape = true
		elseif c == ',' then
			if #current_match > 0 then
				table.insert(result, table.concat(current_match))
			end
			current_match = {}
		else
			table.insert(current_match, c)
		end
	end
	if #current_match > 0 then
		table.insert(result, table.concat(current_match))
	end
	return result
end

function JunitTestParser:_map_to_neotest_result_item(item)
	-- if item.result == nil then
	-- 	log.error('item', vim.inspect(item))
	-- 	-- return {
	-- 	-- 	status = TestStatus.Skipped,
	-- 	-- }
	-- end
	if item.result.status == TestStatus.Failed then
		local results_path = async.fn.tempname()
		lib.files.write(results_path, table.concat(item.result.trace, '\n'))
		local short_message = get_short_error_message(item.result)
		return {
			status = TestStatus.Failed,
			errors = {
				{ message = short_message },
			},
			output = results_path,
			short = short_message,
		}
	elseif item.result.status == TestStatus.Skipped then
		return {
			status = TestStatus.Skipped,
		}
	else
		local results_path
		local log_data
		if item.result.trace then
			log_data = table.concat(item.result.trace, '\n')
			results_path = async.fn.tempname()
		else
			log_data = default_passed_test_output
			results_path = self._get_default_passed_test_output_path()
		end
		lib.files.write(results_path, log_data)
		return {
			status = TestStatus.Passed,
			output = results_path,
		}
	end
end

---@private
function JunitTestParser:parse_test_tree(data)
	local node = {
		test_id = tonumber(data[1]),
		test_name = data[2],
		is_suite = JunitTestParser.strtobool[data[3]],
		test_count = tonumber(data[4]),
		is_dynamic_test = JunitTestParser.strtobool[data[5]],
		parent_id = tonumber(data[6]),
		display_name = data[7],
		parameter_types = data[8],
		unique_id = data[#data],
	}
	assert(data.unique_id ~= '')
	local parent = self:find_result_node(node.parent_id)
	if not parent then
		table.insert(self.test_details, node)
	else
		parent.children = parent.children or {}
		table.insert(parent.children, node)
	end
end

---@private
function JunitTestParser.get_non_junit_test_method(project_name, message)
	local method_name = message:match('(.+)%(')
	local class_name = message:match('%((.+)%)')
	if method_name ~= nil and class_name ~= nil then
		return project_name .. '@' .. class_name .. '#' .. method_name
	end
	return project_name .. '@' .. message
end

---@private
function JunitTestParser:parse_test_start(data)
	local test_id = tonumber(data[1])
	local node = self:find_result_node(test_id)
	assert(node)
	node.result = {}
	node.result.execution = TestExecStatus.Started
end

function JunitTestParser.get_junit5_method_name(rawMethodName)
	local raw_param_strings = rawMethodName:match('%((.+)%)')
	if raw_param_strings == nil then
		return rawMethodName
	end
	-- replease '$' with '.' for nested classes
	raw_param_strings = raw_param_strings:gsub('%$', '.')
	-- replease '\,' with ',' for escaped commas
	raw_param_strings = raw_param_strings:gsub('\\,', ',')
	local params = vim.split(raw_param_strings, ',')
	local result = {}
	for _, param in ipairs(params) do
		param = param:gsub('%s+', '')
		local p = param:match('([^%.]+)$')
		if vim.startswith(param, '%5B') then
			if vim.startswith(param, '%5BL') then
				--- object
				p = param:match('([^%.]+);') .. '[]'
			else
				p = array_lookup[param]
			end
		end
		table.insert(result, p)
	end

	local method_name = rawMethodName:match('(.+)%(')
	return method_name .. '(' .. table.concat(result, ',') .. ')'
end

--@param projectName string
--@param message string
function JunitTestParser.get_test_id_for_junit5_method(projectName, message)
	-- [engine:junit5]/[class:com.example.MyTest]/[method:myTest]/[test-template:myTest(String\, int)]
	local parts = vim.split(message, '/')

	local className = ''
	local methodName = ''
	local invocationSuffix = ''

	if #parts == 0 or parts[1] == '' then
		-- error('Junit4 test method name is not supported')
		return JunitTestParser.get_non_junit_test_method(projectName, message)
	end

	for _, part in ipairs(parts) do
		-- Remove the leading and trailing brackets.
		part = part:match('%[(.-)%]')

		if vim.startswith(part, JUnitTestPart.CLASS) then
			className = part:sub(#JUnitTestPart.CLASS + 1)
		elseif vim.startswith(part, JUnitTestPart.METHOD) then
			local rawMethodName = part:sub(#JUnitTestPart.METHOD + 1)
			-- If the method name exists then we want to include the '#' qualifier.
			methodName = '#' .. JunitTestParser.get_junit5_method_name(rawMethodName)
		elseif vim.startswith(part, JUnitTestPart.TEST_FACTORY) then
			local rawMethodName = part:sub(#JUnitTestPart.TEST_FACTORY + 1)
			-- If the method name exists then we want to include the '#' qualifier.
			methodName = '#' .. JunitTestParser.get_junit5_method_name(rawMethodName)
		elseif vim.startswith(part, JUnitTestPart.NESTED_CLASS) then
			local nestedClassName = part:sub(#JUnitTestPart.NESTED_CLASS + 1)
			className = className .. '$' .. nestedClassName
		elseif vim.startswith(part, JUnitTestPart.TEST_TEMPLATE) then
			local rawMethodName =
				part:sub(#JUnitTestPart.TEST_TEMPLATE + 1):gsub('\\,', ',')
			-- If the method name exists then we want to include the '#' qualifier.
			methodName = '#' .. JunitTestParser.get_junit5_method_name(rawMethodName)
		elseif vim.startswith(part, JUnitTestPart.PROPERTY) then
			local rawMethodName =
				part:sub(#JUnitTestPart.PROPERTY + 1):gsub('\\,', ',')
			-- If the method name exists then we want to include the '#' qualifier.
			methodName = '#' .. JunitTestParser.get_junit5_method_name(rawMethodName)
		elseif vim.startswith(part, JUnitTestPart.TEST_TEMPLATE_INVOCATION) then
			invocationSuffix = invocationSuffix
				.. '['
				.. part:sub(#JUnitTestPart.TEST_TEMPLATE_INVOCATION + 1)
				.. ']'
		elseif vim.startswith(part, JUnitTestPart.DYNAMIC_CONTAINER) then
			invocationSuffix = invocationSuffix
				.. '['
				.. part:sub(#JUnitTestPart.DYNAMIC_CONTAINER + 1)
				.. ']'
		elseif vim.startswith(part, JUnitTestPart.DYNAMIC_TEST) then
			invocationSuffix = invocationSuffix
				.. '['
				.. part:sub(#JUnitTestPart.DYNAMIC_TEST + 1)
				.. ']'
		end
	end
	-- log.error('methodName', methodName)
	if className ~= '' then
		return projectName .. '@' .. className .. methodName, invocationSuffix
	else
		return projectName .. '@' .. message, invocationSuffix
	end
end

---@private
function JunitTestParser:parse_test_end_junit5(node)
	local success, id, invocation = pcall(
		self.get_test_id_for_junit5_method,
		self.context.project_name,
		node.unique_id
	)
	if not success then
		log.error(
			'error during getTestIdForJunit5Method: %s, node: %',
			id,
			vim.inspect(node)
		)
	else
		local test_item = self.context.lookup[id]
		if invocation and invocation ~= '' then
			if not self.results[test_item.key] then
				assert(node.is_dynamic_test)
				self.results[test_item.key] = DynamicTestResult()
			end
			self.results[test_item.key]:append_invocation(invocation, node)
		else
			self.results[test_item.key] = node
		end
	end
end

---@private
function JunitTestParser:parse_test_end_junit(node)
	local success, id = pcall(
		self.get_non_junit_test_method,
		self.context.project_name,
		node.unique_id
	)

	if not success then
		log.error(
			'error during getTestIdForJunitMethod: %s, node: %',
			id,
			vim.inspect(node)
		)
	else
		local test_item = self.context.lookup[id]
		self.results[test_item.key] = node
	end
end

---@private
function JunitTestParser:parse_test_end(data)
	local test_id = tonumber(data[1])
	local node = self:find_result_node(test_id)
	assert(node)
	node.result.execution = TestExecStatus.Ended
	if self.context.test_kind == TestKind.JUnit5 then
		self:parse_test_end_junit5(node)
	else
		self:parse_test_end_junit(node)
	end
end

---@private
function JunitTestParser:parse_test_failed(data, line_iter)
	local test_id = tonumber(data[1])
	local node = self:find_result_node(test_id)
	assert(node)

	node.result.status = TestStatus.Failed

	while true do
		local line = line_iter()

		if line == nil then
			break
		end

		-- EXPECTED
		if vim.startswith(line, MessageId.ExpectStart) then
			node.result.expected = JunitTestParser.get_content_until_end_tag(
				MessageId.ExpectEnd,
				line_iter
			)

		-- ACTUAL
		elseif vim.startswith(line, MessageId.ActualStart) then
			node.result.actual = JunitTestParser.get_content_until_end_tag(
				MessageId.ActualEnd,
				line_iter
			)

		-- TRACE
		elseif vim.startswith(line, MessageId.TraceStart) then
			node.result.trace =
				JunitTestParser.get_content_until_end_tag(MessageId.TraceEnd, line_iter)
		end
	end
end

---@private
function JunitTestParser.get_content_until_end_tag(end_tag, line_iter)
	local content = {}

	while true do
		local line = line_iter()

		if line == nil or vim.startswith(line, end_tag) then
			break
		end

		table.insert(content, line)
	end

	return content
end

---@private
function JunitTestParser:find_result_node(id)
	local function find_node(nodes)
		if not nodes or #nodes == 0 then
			return
		end

		for _, node in ipairs(nodes) do
			if node.test_id == id then
				return node
			end

			local _node = find_node(node.children)

			if _node then
				return _node
			end
		end
	end

	return find_node(self.test_details)
end

---@param text string test result buffer
function JunitTestParser:on_update(text)
	if text:sub(-1) ~= '\n' then
		text = text .. '\n'
	end

	local line_iter = text:gmatch('(.-)\n')
	local line = line_iter()
	while line ~= nil do
		local message_id = line:sub(1, 8):gsub('%s+', '')
		local content = line:sub(9)

		local node_parser = JunitTestParser.node_parsers[message_id]

		if node_parser then
			local data = self._split(content)
			if self[JunitTestParser.node_parsers[message_id]] then
				self[JunitTestParser.node_parsers[message_id]](self, data, line_iter)
			end
		end

		line = line_iter()
	end
end

function JunitTestParser:get_mapped_result()
	local result = {}
	for k, v in pairs(self.results) do
		local data
		if v.is_dynamic_test then
			data = v:get_neotest_result()
		else
			data = self:_map_to_neotest_result_item(v)
		end
		result[k] = data
	end
	return result
end

---@class java_test.TestResultExecutionDetails
---@field actual string[] lines
---@field expected string[] lines
---@field status java_test.TestExecStatus
---@field execution java_test.TestExecutionStatus
---@field trace string[] lines

---@class java_test.TestResults
---@field display_name string
---@field is_dynamic_test boolean
---@field is_suite boolean
---@field parameter_types string
---@field parent_id integer
---@field test_count integer
---@field test_id integer
---@field test_name string
---@field unique_id string
---@field result java_test.TestResultExecutionDetails
---@field children java_test.TestResults[]

return JunitTestParser
