--- junit_result_parser.lua
--- Based on https://github.com/microsoft/vscode-java-test

local log = require('neotest-jdtls.log')

--- @class JunitResultParser
--- @field lines string[]
--- @field test_items table<string, TestItem>
local JunitResultParser = {}

function JunitResultParser:new()
	local o = setmetatable({}, self)
	o.lines = {}
	o.test_items = {}
	self.__index = self
	return o
end

--- @class TestItem
--- @field is_suite boolean
--- @field test_cout number
--- @field full_name string
--- @field name string
--- @field method string
--- @field class string
--- @field dynamic_test_details string
--- @field current_state number
--- @field error TestItemError
local TestItem = {}

function TestItem:new(
	full_name,
	dynamic_test_details,
	isSuite,
	testCount,
	method,
	class
)
	local item = {}
	item.full_name = full_name
	item.dynamic_test_details = dynamic_test_details
	item.is_suite = isSuite
	item.test_cout = testCount
	item.method = method
	item.class = class
	self.__index = self
	setmetatable(item, self)
	return item
end

--- @class TestItemError
--- @field stack_trace string
--- @field expected string
--- @field actual string
local TestItemError = {}

function TestItemError:new()
	local error = {}
	self.__index = self
	setmetatable(error, self)
	return error
end

--- @enum
local JunitTestResultState = {
	-- Test will be run, but is not currently running.
	Queued = 1,
	-- Test is currently running
	Running = 2,
	-- Test run has passed
	Passed = 3,
	-- Test run has failed (on an assertion)
	Failed = 4,
	-- Test run has been skipped
	Skipped = 5,
	-- Test run failed for some other reason (compilation error, timeout, etc)
	Errored = 6,
}

JunitResultParser.junit_test_result_state = JunitTestResultState

---@enum MessageId
local MessageId = {
	-- Notification about a test inside the test suite.
	-- TEST_TREE + testId + "," + testName + "," + isSuite + "," + testCount + "," + isDynamicTest +
	-- "," + parentId + "," + displayName + "," + parameterTypes + "," + uniqueId
	-- isSuite = "true" or "false"
	-- isDynamicTest = "true" or "false"
	-- parentId = the unique id of its parent if it is a dynamic test, otherwise can be "-1"
	-- displayName = the display name of the test
	-- parameterTypes = comma-separated list of method parameter types if applicable, otherwise an
	-- empty string
	-- uniqueId = the unique ID of the test provided by JUnit launcher, otherwise an empty string
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

---@enum RecoringType
local RecordingType = {
	None = 'None',
	StackTrace = 'StackTrace',
	ExpectMessage = 'ExpectMessage',
	ActualMessage = 'ActualMessage',
}

---Returns a stream reader function
---@param conn uv_tcp_t
---@return fun(err: string, buffer: string)
function JunitResultParser:get_stream_reader(conn)
	return vim.schedule_wrap(function(err, buffer)
		if err then
			return
		end

		if buffer then
			local lines = vim.split(buffer, '\n')
			for _, line in ipairs(lines) do
				table.insert(self.lines, line)
			end
		else
			conn:close()
		end
	end)
end

function JunitResultParser:get_plain_results()
	return table.concat(self.lines, '\n')
end

---@param start_line string
---@param message_id MessageId
---@return string
function JunitResultParser.get_test_index(start_line, message_id)
	local sp = vim.split(start_line, message_id)[2]
	local index = vim.split(sp, ',')[1]
	local str = string.gsub(index, '%s+', '')
	return str
end

local function clean(input)
	return input:gsub('\n$', '')
end

function JunitResultParser:enlist_to_test_mapping(message)
	local result = vim.split(message, ',')
	local fullName = result[2]
	local isSuite = result[3] == 'true'
	local testCount = tonumber(result[4])
	local is_dynamic = result[5] == 'true'
	local method, class = fullName:match('([^(]+)%(([^)]+)%)')

	local dynamic_test_details = nil
	if is_dynamic then
		dynamic_test_details = result[7]
	end

	local index = JunitResultParser.get_test_index(message, MessageId.TestTree)
	local test_item = TestItem:new(
		fullName,
		dynamic_test_details,
		isSuite,
		testCount,
		method,
		class
	)
	log.debug(
		'enlist_to_test_mapping',
		'index',
		index,
		'test_item',
		vim.inspect(test_item)
	)
	self.test_items[index] = test_item
end

--- @return TestItem
function JunitResultParser:get_test_item(line, message_id)
	local index = JunitResultParser.get_test_index(line, message_id)
	return self.test_items[index]
end

--- @param data string
--- @param item TestItem
function JunitResultParser.determine_result_state_at_end(data, item)
	if string.find(data, MessageId.IGNORE_TEST_PREFIX) ~= nil then
		item.current_state = JunitTestResultState.Skipped
	elseif item.current_state == JunitTestResultState.Running then
		item.current_state = JunitTestResultState.Passed
	end
end

function JunitResultParser:initialize_tracing_cache(item)
	item.error = TestItemError:new()
	self.tracingItem = item
	self.traces = nil
	self.assertionFailure = nil
	self.expectString = ''
	self.actualString = ''
	self.stack_trace = ''
end

function JunitResultParser:clear_tracing_cache()
	self.tracingItem = nil
	self.traces = nil
	self.assertionFailure = nil
	self.expectString = ''
	self.actualString = ''
	self.stack_trace = ''
end

function JunitResultParser:parse()
	for _, line in ipairs(self.lines) do
		if vim.startswith(line, MessageId.TestTree) then
			self:enlist_to_test_mapping(line)
		elseif vim.startswith(line, MessageId.TestStart) then
			local test_item = self:get_test_item(line, MessageId.TestStart)
			test_item.current_state = JunitTestResultState.Running
		elseif vim.startswith(line, MessageId.TestEnd) then
			local test_item = self:get_test_item(line, MessageId.TestEnd)
			self.determine_result_state_at_end(line, test_item)
		elseif vim.startswith(line, MessageId.TestFailed) then
			local test_item = self:get_test_item(line, MessageId.TestFailed)
			test_item.current_state = JunitTestResultState.Failed
			self:initialize_tracing_cache(test_item)
		elseif vim.startswith(line, MessageId.TestError) then
			local test_item = self:get_test_item(line, MessageId.TestError)
			test_item.current_state = JunitTestResultState.Failed
			self:initialize_tracing_cache(test_item)
		elseif vim.startswith(line, MessageId.TraceStart) then
			self.recording_type = RecordingType.StackTrace
		elseif vim.startswith(line, MessageId.TraceEnd) then
			self.recording_type = RecordingType.None
			self.tracingItem.error.stack_trace = clean(self.stack_trace)
			self:clear_tracing_cache()
		elseif vim.startswith(line, MessageId.ExpectStart) then
			self.recording_type = RecordingType.ExpectMessage
		elseif vim.startswith(line, MessageId.ExpectEnd) then
			self.tracingItem.error.expected = clean(self.expectString)
			self.recording_type = RecordingType.None
		elseif vim.startswith(line, MessageId.ActualStart) then
			self.recording_type = RecordingType.ActualMessage
		elseif vim.startswith(line, MessageId.ActualEnd) then
			self.tracingItem.error.actual = clean(self.actualString)
			self.recording_type = RecordingType.None
		elseif self.recording_type == RecordingType.StackTrace then
			self.stack_trace = self.stack_trace .. line .. '\n'
		elseif self.recording_type == RecordingType.ActualMessage then
			self.actualString = self.actualString .. line .. '\n'
		elseif self.recording_type == RecordingType.ExpectMessage then
			self.expectString = self.expectString .. line .. '\n'
		end
	end
end

return JunitResultParser
