local log = require('neotest-jdtls.utils.log')

local M = {}

local function echo(message, level)
	local plugin_name = 'neotest-jdtls'
	vim.api.nvim_echo({ { plugin_name .. ': ' .. message, level } }, true, {})
end

function M.echo_ok(message)
	log.debug(message)
	echo(message, 'DiagnosticOk')
end

function M.echo_warn(message)
	log.warn(message)
	echo(message, 'DiagnosticWarn')
end

return M
