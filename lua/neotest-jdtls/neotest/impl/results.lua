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
	return spec.context.report()
end

return M

---@class neotest.NodeData
