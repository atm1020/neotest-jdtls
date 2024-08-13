local jdtls = require('neotest-jdtls.utils.jdtls')
local log = require('neotest-jdtls.utils.log')

local M = {}

function M.root(_)
	local root_dir = jdtls.root_dir()
	log.debug('root_dir', root_dir)
	return root_dir
end

return M
