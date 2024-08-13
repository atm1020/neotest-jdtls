local JUnitReport = require('neotest-jdtls.junit.reports.junit')
local log = require('neotest-jdtls.utils.log')
local TestLevel = require('neotest-jdtls.utils.jdtls').TestLevel
local nio = require('nio')
local jdtls = require('neotest-jdtls.utils.jdtls')

local M = {}

local function get_dap_launcher_config(launch_args, java_exec, config)
	return {
		name = config.label,
		type = 'java',
		request = 'launch',
		mainClass = launch_args.mainClass,
		projectName = launch_args.projectName,
		noDebug = not config.debug,
		javaExec = java_exec,
		cwd = launch_args.workingDirectory,
		classPaths = launch_args.classpath,
		modulePaths = launch_args.modulepath,
		vmArgs = table.concat(launch_args.vmArguments, ' '),
		args = table.concat(launch_args.programArguments, ' '),
		-- env: config?.env,
		-- envFile: config?.envFile,
		-- sourcePaths: config?.sourcePaths,
		-- preLaunchTask: config?.preLaunchTask,
		-- postDebugTask: config?.postDebugTask,
	}
end

local function setup(server, dap_launcher_config, report)
	server:bind('127.0.0.1', 0)
	server:listen(128, function(err)
		assert(not err, err)
		local sock = assert(vim.loop.new_tcp(), 'uv.new_tcp must return handle')
		server:accept(sock)
		local success = sock:read_start(report:get_stream_reader(sock))
		assert(success == 0, 'failed to listen to reader')
	end)
	dap_launcher_config.args = dap_launcher_config.args:gsub(
		'-port ([0-9]+)',
		'-port ' .. server:getsockname().port
	)
	return dap_launcher_config
end

---@return JavaTestItem
---@param test_file_uri string
local function get_java_test_item(test_file_uri)
	---@type JavaTestItem
	local java_test_items = jdtls.find_test_types_and_methods(test_file_uri)
	return java_test_items
end

--- @param test_file_uri string
--- @return JunitLaunchRequestArguments
local function handle_test(data, test_file_uri)
	local java_test_items = get_java_test_item(test_file_uri)
	assert(#java_test_items ~= 0, 'No test items found')
	local java_test_item = java_test_items[1]
	---@type JavaTestItem
	local closest_item = nil
	local end_line = data.range[3]
	for _, children in ipairs(java_test_item.children) do
		if children.range['end'].line == end_line then
			closest_item = children
			break
		end
		closest_item = children
	end

	return {
		projectName = closest_item.projectName,
		testLevel = TestLevel.Method,
		testKind = closest_item.testKind,
		testNames = { closest_item.jdtHandler },
	}
end

--- @param test_file_uri string
--- @return JunitLaunchRequestArguments|nil
local function handle_dir(tree, test_file_uri)
	local file_nodes = {}
	for _, node in tree:iter_nodes() do
		local node_data = node:data()
		if
			node_data.type == 'file'
			and vim.startswith(vim.uri_from_fname(node_data.path), test_file_uri)
		then
			file_nodes[node_data.id] = vim.uri_from_fname(node_data.path)
		end
	end
	local items = {}
	local project_name = nil
	local test_kind = nil
	for _, url in pairs(file_nodes) do
		local java_test_items = get_java_test_item(url)
		if java_test_items and #java_test_items == 1 then
			local java_test_item = java_test_items[1]
			table.insert(items, java_test_item.fullName)
			if project_name == nil then
				project_name = java_test_item.projectName
			end
			if test_kind == nil then
				test_kind = java_test_item.testKind
			end
		else
			log.warn('Unexpected number of test items found for ', url)
		end
	end

	if #items == 0 then
		log.warn('No project name found')
		return nil
	end

	return {
		projectName = project_name,
		testLevel = TestLevel.Class,
		testKind = test_kind,
		testNames = items,
	}
end

--- @param test_file_uri string
--- @return JunitLaunchRequestArguments|nil
local function handle_file(test_file_uri)
	local java_test_items = get_java_test_item(test_file_uri)
	if not java_test_items or #java_test_items == 0 then
		log.info('No test items found')
		return nil
	end
	local java_test_item = java_test_items[1]
	return {
		projectName = java_test_item.projectName,
		testLevel = TestLevel.Class,
		testKind = java_test_item.testKind,
		testNames = { vim.split(java_test_item.fullName, '#')[1] },
	}
end

local function shutdown_server(server)
	if server then
		server:shutdown()
		server:close()
		log.debug('server closed')
	end
end

local function run_test(dap_launcher_config, server)
	local event = nio.control.event()
	nio.run(function()
		require('dap').run(dap_launcher_config, {
			after = function(_)
				shutdown_server(server)
				event.set()
			end,
		})
	end)
	event.wait()
end

---@param test_file_uri string
---@return JunitLaunchRequestArguments|nil
local function resolve_junit_launch_arguments(tree, test_file_uri)
	local data = tree:data()
	---@type JunitLaunchRequestArguments|nil
	local arguments
	if data.type == 'test' then
		arguments = handle_test(data, test_file_uri)
	elseif data.type == 'dir' then
		arguments = handle_dir(tree, test_file_uri)
	elseif data.type == 'file' or data.type == 'namespace' then
		arguments = handle_file(test_file_uri)
	else
		error('Unsupported type: ' .. data.type)
	end
	if not arguments then
		return nil
	end
	return jdtls.get_junit_launch_arguments(arguments)
end

---@param args neotest.RunArgs
---@return neotest.RunSpec
function M.build_spec(args)
	local strategy = args.strategy
	local tree = args and args.tree
	local data = tree:data()
	local test_file_uri = vim.uri_from_fname(data.path)

	local junit_launch_arguments =
		resolve_junit_launch_arguments(tree, test_file_uri)
	if not junit_launch_arguments then
		return {
			context = {
				file = data.path,
				pos_id = data.id,
				type = data.type,
			},
		}
	end

	local executable = jdtls.resolve_java_executable(
		junit_launch_arguments.mainClass,
		junit_launch_arguments.projectName
	)

	local is_debug = strategy == 'dap'
	local dap_launcher_config =
		get_dap_launcher_config(junit_launch_arguments, executable, {
			debug = is_debug,
			label = 'Launch All Java Tests',
		})
	log.debug('dap_launcher_config', vim.inspect(dap_launcher_config))
	local report = JUnitReport()
	local server = assert(vim.loop.new_tcp(), 'uv.new_tcp() must return handle')
	dap_launcher_config = setup(server, dap_launcher_config, report)

	local config = {}
	if not is_debug then
		-- TODO implement console for non-debug mode
		-- local dapui       = require('dapui')
		-- local console_buf = dapui.elements.console.buffer()
		run_test(dap_launcher_config, server)
	else
		dap_launcher_config.after = function()
			nio.run(function()
				shutdown_server(server)
			end)
		end
		config = dap_launcher_config
	end

	local context = {
		file = data.path,
		pos_id = data.id,
		type = data.type,
		report = report,
	}
	local response = {
		context = context,
		strategy = config,
	}
	return response
end

return M

--- @class JunitLaunchRequestArguments
--- @field projectName string
--- @field mainClass string
--- @field testLevel number
--- @field testKind string
--- @field testNames string[]

---@class ResolvedMainClass
---@field mainClass string
---@field projectName string
