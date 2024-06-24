local async = require('neotest.async')
local log = require('neotest-jdtls.log')
local lib = require('neotest.lib')

local M = {}

local TestStatus = {
	Failed = 'failed',
	Skipped = 'skipped',
	Passed = 'passed',
}

local function get_short_error_message(result)
	if result.actual and result.expected then
		return string.format(
			'Expected: [%s] but was [%s]',
			result.expected[1],
			result.actual[1]
		)
	end
	local trace_result = ''
	for idx, trace in ipairs(result.trace) do
		trace_result = trace_result .. trace
		if idx > 3 then
			break
		end
	end
	return trace_result
end

local function map_to_neotest_result_item(item)
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
		local results_path = async.fn.tempname()
		local log_data
		if item.result.trace then
			log_data = table.concat(item.result.trace, '\n')
		else
			log_data = 'Test passed (There is no output available)'
		end
		lib.files.write(results_path, log_data)
		return {
			status = TestStatus.Passed,
			output = results_path,
		}
	end
end

local function group_and_map_test_results(test_result_lookup, suite)
	for _, ch in ipairs(suite.children) do
		local key = vim.split(ch.test_name, '%(')[1]
		if not ch.is_suite then
			if test_result_lookup[key] == nil then
				test_result_lookup[key] = {}
			end
			table.insert(test_result_lookup[key], map_to_neotest_result_item(ch))
		else
			group_and_map_test_results(test_result_lookup, ch)
		end
	end
end

local function merge_neotest_results(test_result_lookup, node_data)
	if test_result_lookup[node_data.name] == nil then
		log.debug('No test results found for', node_data.name)
		return nil -- Maybe "status = Skipped" would be better with some message
	end

	if #test_result_lookup[node_data.name] == 1 then
		return test_result_lookup[node_data.name][1]
	end

	local dynamic_test_result = {
		status = TestStatus.Passed,
	}
	for _, result in ipairs(test_result_lookup[node_data.name]) do
		-- TODO merge stack traces
		if result.status == TestStatus.Failed then
			dynamic_test_result.status = TestStatus.Failed
			dynamic_test_result.errors = result.errors
			dynamic_test_result.output = result.output
			break
		end
	end
	return dynamic_test_result
end

---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
function M.results(spec, _, tree)
	local test_result_lookup = {}
	local report = spec.context.report:get_results()
	for _, item in ipairs(report) do
		group_and_map_test_results(test_result_lookup, item)
	end
	local results = {}
	for _, node in tree:iter_nodes() do
		local node_data = node:data()
		log.debug('node', vim.inspect(node))
		local node_result = merge_neotest_results(test_result_lookup, node_data)
		if node_result then
			results[node_data.id] = node_result
		end
	end
	return results
end

return M
