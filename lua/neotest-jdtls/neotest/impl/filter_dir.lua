local log = require('neotest-jdtls.utils.log')
local project = require('neotest-jdtls.utils.project')

local M = {}

function M.filter_dir(name, rel_path, _)
	local path_ok = false
	local current_project = project.get_current_project()
	if current_project.test_folders[rel_path] then
		path_ok = true
	end
	log.debug('filter_dir result:', name, rel_path, path_ok)
	return path_ok
end

return M
