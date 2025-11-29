local log = require('neotest-jdtls.utils.log')
local project = require('neotest-jdtls.utils.project')
local jdtls = require('neotest-jdtls.utils.jdtls')
local M = {}

function M.is_test_file(file_path)
	if not jdtls.jdtls_attached then
		return false
	end

	-- Neotest may call this function multiple times while the jdtls request is still in progress,
	-- so we need to prevent to call the same jdtls request multiple times.
	if project.project_loading_in_progress then
		return false
	end

	local current_project = project.get_current_project()
	local path = vim.uri_from_fname(file_path)
	local is_test_file = current_project.methods[path] or false
	log.debug(
		'is_test_file result: ',
		file_path,
		path,
		is_test_file,
		vim.inspect(current_project.methods)
	)
	return is_test_file
end

return M
