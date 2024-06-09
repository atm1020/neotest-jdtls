local utils = require('neotest-jdtls.utils')
local log = require('neotest-jdtls.log')

local M = {}

function M.root(dir)
	local root_dir = utils.jdtls().config.root_dir
	log.debug('input', dir, 'root_dir', root_dir)
	-- return root_dir
	return dir
end

return M
