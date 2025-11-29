local log = require('neotest-jdtls.utils.log')
local adapter = require('neotest-jdtls.neotest.adapter')
local project = require('neotest-jdtls.utils.project')
local jdtls = require('neotest-jdtls.utils.jdtls')
local echo_warn = require('neotest-jdtls.utils.notify').echo_warn
local echo_ok = require('neotest-jdtls.utils.notify').echo_ok

local group = vim.api.nvim_create_augroup('neotest-jdtls', { clear = true })

vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
	pattern = '*.java',
	callback = function()
		project.clear_project_cache()
	end,
	group = group,
})

vim.api.nvim_create_user_command(
	'NeotestJdtlsClearProjectCache',
	project.clear_project_cache,
	{}
)

vim.api.nvim_create_autocmd('LspAttach', {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client then
			return
		end
		if client.name == 'jdtls' then
			log.debug('jdtls client attached')
			jdtls.jdtls_attached = true
			echo_ok('The jdtls client attached.')
		end
	end,
	group = group,
})

vim.api.nvim_create_autocmd('LspDetach', {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client then
			return
		end
		if client.name == 'jdtls' then
			log.debug('jdtls client detached')
			jdtls.jdtls_attached = false
			project.clear_project_cache()
			echo_warn(
				'The jdtls client detached. Neotest-jdtls is unavailable until it reattaches.'
			)
		end
	end,
	group = group,
})

return adapter
