local health = vim.health
local project = require('neotest-jdtls.utils.project')
local log = require('neotest-jdtls.utils.log')

local M = {}

local function check_jdtls_is_attached()
	local clients = vim.lsp.get_clients({ name = 'jdtls' })
	if #clients < 1 then
		health.warn(
			'The jdtls client is not attached. Neotest-jdtls functionality unavailable until jdtls is attached.'
		)
		return false
	end
	health.ok('The jdtls client is attached')
	return true
end

local function list_pending_jdtls_requests()
	local clients = vim.lsp.get_clients({ name = 'jdtls' })
	--- @class vim.lsp.Client
	local client = clients[1]
	local request = client.requests
	if not request or vim.tbl_isempty(request) then
		return
	end
	health.info('Pending jdtls request:')
	for _, req in pairs(client.requests) do
		if req.type == 'pending' then
			health.info(' > ' .. req.method)
		end
	end
end

local function create_project_loading_health_message()
	health.warn(
		'The project is still loading. Neotest-jdtls functionality unavailable until loading is complete.'
	)
	list_pending_jdtls_requests()
end

local function check_project_is_loaded()
	log.error(
		'project_loading_in_progress:',
		project.project_loading_in_progress,
		'project_cache is nil:',
		project.project_cache == nil
	)
	if
		not project.project_loading_in_progress and project.project_cache == nil
	then
		health.info(
			'Neotest does not triggered, so project loading has not started yet.'
		)
		return
	end

	if project.project_loading_in_progress then
		create_project_loading_health_message()
		return
	end
	if project.project_cache == nil then
		create_project_loading_health_message()
		return
	end

	health.ok("Project '" .. project.project_cache.project_name .. "' is loaded")
end

function M.check()
	health.start('neotest-jdtls health check')
	if not check_jdtls_is_attached() then
		return
	end
	check_project_is_loaded()
end

return M
