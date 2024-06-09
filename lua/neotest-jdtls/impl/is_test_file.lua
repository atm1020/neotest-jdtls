local log = require('neotest-jdtls.log')
local M = {}

M.is_test_file = function(file_path)
	local is_test_file = string.find(file_path, 'test') ~= nil
		and string.find(file_path, '.java') ~= nil
		and string.find(file_path, '.class') == nil
	log.debug('is_test_file: ', is_test_file)
	return is_test_file
end

return M
