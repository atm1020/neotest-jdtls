local async = require('neotest.async')
local log = require('neotest-jdtls.log')
local lib = require('neotest.lib')
local JunitTestResultState =
	require('neotest-jdtls.junit_result_parser').junit_test_result_state

local M = {}

local NeotestTestStatus = {
	Failed = 'failed',
	Skipped = 'skipped',
	Passed = 'passed',
}

local function get_short_msg(error)
	log.debug('error: ', vim.inspect(error))
	if error.expected and error.actual then
		return 'Expected '
			.. '['
			.. error.expected
			.. '] but was ['
			.. error.actual
			.. ']'
	end
	return vim.split(error.stack_trace, '\n')[1]
end

---@param item TestItem
local function get_result(item)
	if not item.current_state then
		return {}
	end
	local result_state = item.current_state
	local results_path = async.fn.tempname()
	if result_state == JunitTestResultState.Failed then
		lib.files.write(results_path, item.error.stack_trace)
		local short_msg = get_short_msg(item.error)
		return {
			status = NeotestTestStatus.Failed,
			errors = {
				{ message = short_msg },
			},
			output = results_path,
			short = short_msg,
		}
	elseif result_state == JunitTestResultState.Skipped then
		return {
			status = NeotestTestStatus.Skipped,
		}
	else
		local log_data = 'Test passed (There is no output available)'
		lib.files.write(results_path, log_data)
		return {
			status = NeotestTestStatus.Passed,
		}
	end
end

---@param dynamic_tests table<string, TestItem[]>
local function get_result_for_dynamic(dynamic_tests, results)
	log.debug('dynamic_tests: ', vim.inspect(dynamic_tests))
	for _, tests in pairs(dynamic_tests) do
		local result = {
			status = NeotestTestStatus.Passed,
		}
		local key = nil
		local results_path = async.fn.tempname()
		local errMsg = ''
		for _, test in pairs(tests) do
			if not key then
				key = test.method
			end
			if test.current_state == JunitTestResultState.Failed then
				result.errors = {
					{ message = get_short_msg(test.error) },
				}
				errMsg = errMsg
					.. '\n------------------------------------ \n'
					.. 'inv='
					.. test.dynamic_test_details
					.. '\n------------------------------------ \n'
					.. ' \n'
					.. test.error.stack_trace
				result.status = NeotestTestStatus.Failed
			elseif test.current_state == JunitTestResultState.Skipped then
				result.status = NeotestTestStatus.Skipped
			end
		end
		if errMsg ~= '' then
			lib.files.write(results_path, errMsg)
			result.output = results_path
		end
		results[key] = result
	end
end

---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
function M.results(spec, _, tree)
	local result_map = {}

	--- @type JunitResultParser
	local parser = spec.context.parser
	parser:parse()

	--- @type table<string, TestItem[]>
	local dynamic_tests = {}
	log.debug('plain test output: ', vim.inspect(parser:get_plain_results()))

	for _, testItem in pairs(parser.test_items) do
		log.debug('testItem: ', vim.inspect(testItem))
		if testItem.current_state then -- TODO filter in the analyzer
			if testItem.dynamic_test_details then
				if not dynamic_tests[testItem.full_name] then
					dynamic_tests[testItem.full_name] = {}
				end
				table.insert(dynamic_tests[testItem.full_name], testItem)
			else
				local key = testItem.method
				if key then
					result_map[key] = get_result(testItem)
				end
			end
		end
	end
	get_result_for_dynamic(dynamic_tests, result_map)

	local results = {}
	for _, node in tree:iter_nodes() do
		local node_data = node:data()
		local node_result = result_map[node_data.name]
		if node_result then
			results[node_data.id] = node_result
		end
	end
	return results
end

return M
