local async = require('neotest.async')
local log = require('neotest-jdtls.utils.log')
local lib = require('neotest.lib')
local project = require('neotest-jdtls.utils.project')
local jdtls = require('neotest-jdtls.utils.jdtls')
local nio = require('nio')

local default_passed_test_output =
	'The console output is available in the DAP console.'
---@type string|nil
local default_passed_test_output_path = nil

local M = {}

--- @enum TestStatus
local TestStatus = {
	Failed = 'failed',
	Skipped = 'skipped',
	Passed = 'passed',
}

local function get_default_passed_test_output_path()
	if not default_passed_test_output_path then
		default_passed_test_output_path = async.fn.tempname()
		lib.files.write(default_passed_test_output_path, default_passed_test_output)
	end
	return default_passed_test_output_path
end

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
		local results_path
		local log_data
		if item.result.trace then
			log_data = table.concat(item.result.trace, '\n')
			results_path = async.fn.tempname()
		else
			log_data = default_passed_test_output
			results_path = get_default_passed_test_output_path()
		end
		lib.files.write(results_path, log_data)
		return {
			status = TestStatus.Passed,
			output = results_path,
		}
	end
end

local function get_test_key_from_junit_result(test_name)
	--  test_name format: "function_name(package.name.ClassName)"
	log.debug('get_test_key_from_junit_result input:', test_name)
	local function_name = test_name:match('^(.+)%(') -- Extract "function_name"
	local class_name = test_name:match('%.([%w$]+)%)$') -- Extract "ClassName"

	assert(function_name, 'function name not found')
	assert(class_name, 'class name not found')
	local key = class_name .. '::' .. function_name
	log.debug('get_test_key_from_junit_result output:', key)
	return key
end

local function get_test_key_from_neotest_id(test_id)
	-- test_id format: "/path/to/file::class_name::function_name"
	log.debug('get_test_key_from_neotest_id input:', test_id)
	local key = test_id:match('::(.+)$')
	log.debug('get_test_key_from_neotest_id output:', key)
	return key
end

local function group_and_map_test_results(test_result_lookup, suite)
	for _, ch in ipairs(suite.children) do
		if not ch.is_suite then
			local key = get_test_key_from_junit_result(ch.test_name)
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
	log.debug('Before|Merging test results', vim.inspect(node_data))
	local key = get_test_key_from_neotest_id(node_data.id)
	if test_result_lookup[key] == nil then
		local root = jdtls.root_dir()
		nio.scheduler()
		local current = project.get_current_project()
		local path = node_data.path:sub(#root + 2)
		--- If the node type is 'dir', and not in the project test folders (it's means there are no tests in it)
		--- then mark it as skipped.
		if not current.test_folders[path] and node_data.type == 'dir' then
			return {
				status = TestStatus.Skipped,
			}
		end
		return nil
	end

	if #test_result_lookup[key] == 1 then
		return test_result_lookup[key][1]
	end

	local dynamic_test_result = {
		status = TestStatus.Passed,
		output = get_default_passed_test_output_path(),
	}
	for _, result in ipairs(test_result_lookup[key]) do
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
	log.debug('Parsing test results', vim.inspect(spec.context.report))
	default_passed_test_output_path = nil
	--- Set the results to skipped if the report is not available
	if not spec.context.report then
		local results = {}
		for _, node in tree:iter_nodes() do
			local node_data = node:data()
			results[node_data.id] = {
				status = TestStatus.Skipped,
			}
		end
		return results
	end

	local test_result_lookup = {}
	local report = spec.context.report:get_results()
	for _, item in ipairs(report) do
		if item.children then
			group_and_map_test_results(test_result_lookup, item)
		end
	end

	local results = {}
	for _, node in tree:iter_nodes() do
		local node_data = node:data()
		local node_result = merge_neotest_results(test_result_lookup, node_data)
		if node_result then
			results[node_data.id] = node_result
		end
	end
	return results
end

return M
