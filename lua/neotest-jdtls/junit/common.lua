local M = {}

function M.get_short_error_message(result)
	if result.actual and result.expected then
		return string.format(
			'Expected: [%s] but was [%s]',
			result.expected[1],
			result.actual[1]
		)
	end
	local trace_result = ''
	for idx, trace in ipairs(result.trace) do
		trace_result = trace_result .. trace
		if idx > 3 then
			break
		end
	end
	return trace_result
end

return M
