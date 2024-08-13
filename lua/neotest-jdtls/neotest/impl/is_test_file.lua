local log = require('neotest-jdtls.utils.log')
local project = require('neotest-jdtls.utils.project')
local M = {}

function M.is_test_file(file_path)
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
