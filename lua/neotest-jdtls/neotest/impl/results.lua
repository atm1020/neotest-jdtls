local log = require('neotest-jdtls.utils.log')
local TestStatus = require('neotest-jdtls.types.enums').TestStatus
local M = {}

---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
function M.results(spec, _, tree)
	log.debug('Parsing test results', vim.inspect(spec.context.report))
	-- default_passed_test_output_path = nil

	-- - Set the results to skipped if the report is not available
	if not spec.context.report then
		local results = {}
		for _, node in tree:iter_nodes() do
			local node_data = node:data()
			results[node_data.id] = {
				status = TestStatus.Skipped,
				message = 'Report not available',
			}
		end
		return results
	end
<<<<<<< HEAD

    local report = spec.context.report:get_results()
    for _, node in tree:iter_nodes() do
        local node_data = node:data()
        log.debug(node_data)
    end
    log.debug(report)
    if report.testType == 2 then -- TestNG
        log.debug("Returning TestNG result", report.results)
        return report.results
    end

	local test_result_lookup = {}
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
=======
	return spec.context.report()
>>>>>>> main
end

return M

---@class neotest.NodeData
