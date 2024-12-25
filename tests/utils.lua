local M = {}

function M.test_name_format(expected, input)
	return string.format('\nexpected: %s\ninput %s\n', expected, input)
end

return M
