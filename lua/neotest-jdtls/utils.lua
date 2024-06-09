local log = require('neotest-jdtls.log')

local M = {}

M.symbol_query = [[
        ;query
	;Capture variable declaration
	(type_identifier) @symbol
]]

function M.jdtls()
	local clients = vim.lsp.get_active_clients({ name = 'jdtls' })

	if #clients > 1 then
		error('Could not find any running jdtls clients')
	end

	return clients[1]
end

---Executes workspace command on jdtls
---@param cmd_info {command: string, arguments: any }
---@param timeout number?
---@param buffer number?
---@return { err: { code: number, message: string }, result: any }
function M.execute_command(cmd_info, timeout, buffer)
	timeout = timeout and timeout or 5000
	buffer = buffer and buffer or 0
	log.debug(
		'Executing command:',
		'[' .. cmd_info.command .. ']',
		'with args:',
		vim.inspect(cmd_info.arguments)
	)
	local result = M.jdtls()
		.request_sync('workspace/executeCommand', cmd_info, timeout, buffer)
	log.debug(
		'Command',
		'[' .. cmd_info.command .. ']',
		'executed with result:',
		vim.inspect(result)
	)
	return result
end

return M
