local log = require('neotest-jdtls.log')
local M = {}

M.is_test_file = function(file_path)
	local is_test_file = vim.endswith(file_path, 'Test.java')
		or vim.endswith(file_path, 'Tests.java')
	log.debug('is_test_file: ', is_test_file)
	return is_test_file
end

return M
