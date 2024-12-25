local class = require('neotest-jdtls.utils.class')
local log = require('neotest-jdtls.utils.log')
local TestKind = require('neotest-jdtls.types.enums').TestKind
local jdtls = require('neotest-jdtls.utils.jdtls')
local TestLevel = require('neotest-jdtls.types.enums').TestLevel
local nio = require('nio')
local TestContext = require('neotest-jdtls.utils.test_context')

---@class BaseRunner
---@field context TestContext
---@field test_kind TestKind
---@field server uv_tcp_t
local BaseRunner = class()

function BaseRunner:_init()
	self.context = TestContext()
end

---@protected
function BaseRunner.get_base_dap_launcher_config(launch_args, java_exec, config)
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
		-- env:config?.env,
		-- envFile:config?.envFile,
		-- sourcePaths:config?.sourcePaths,
		-- preLaunchTask:config?.preLaunchTask,
		-- postDebugTask:config?.postDebugTask,
	}
end

function BaseRunner.test_item_to_neotest_id(java_test_item)
	local nested_class
	local id = java_test_item.id
	local method_name
	if java_test_item.testKind == TestKind.JUnit then
		method_name = id:match('#(.+)$')
	else
		method_name = id:match('#(.+)%(')
	end

	local class_full_path = id:match('@(.-)%$')
	if class_full_path == nil then
		class_full_path = id:match('@(.+)%#')
		if class_full_path == nil then
			class_full_path = id:match('@(.+)$')
		end
	else
		nested_class = id:match('%$(.+)%#')
		if nested_class == nil then
			nested_class = id:match('%$(.+)$')
		end
	end

	local class_parts = {}
	for part in class_full_path:gmatch('[^%.]+') do
		table.insert(class_parts, part)
	end
	local class_name = class_parts[#class_parts]

	local uri = java_test_item.uri
	local result = uri .. '::' .. class_name

	if nested_class ~= nil then
		result = result .. '::' .. nested_class
	end

	if method_name ~= nil then
		result = result .. '::' .. method_name
	end
	return vim.uri_to_fname(result)
end

---@private
function BaseRunner.load_lookup(id, java_test_item)
	if not java_test_item.children then
		return nil
	end
	for _, children in ipairs(java_test_item.children) do
		local neotest_id = BaseRunner.test_item_to_neotest_id(children)
		-- log.error('neotest_id', neotest_id)
		if id == neotest_id then
			return children
		end

		local c = BaseRunner.load_lookup(id, children)
		if c ~= nil then
			return c
		end
	end
end

---@private
---@param parser BaseParser
function BaseRunner:setup(parser)
	self.server:bind('127.0.0.1', 0)
	self.server:listen(128, function(err)
		assert(not err, err)
		local sock = assert(vim.loop.new_tcp(), 'uv.new_tcp must return handle')
		self.server:accept(sock)
		local success = sock:read_start(parser:get_stream_reader(sock))
		assert(success == 0, 'failed to listen to reader')
	end)
end

---@private
---@return JavaTestItem
---@param test_file_uri string
function BaseRunner.get_java_test_item(test_file_uri)
	---@type JavaTestItem
	local java_test_items = jdtls.find_test_types_and_methods(test_file_uri)
	log.debug('java_test_items', vim.inspect(java_test_items))
	return java_test_items
end

---@private
--- @param test_file_uri string
--- @return JunitLaunchRequestArguments
function BaseRunner:handle_test(data, test_file_uri)
	local java_test_items = self.get_java_test_item(test_file_uri)

	assert(#java_test_items ~= 0, 'No test items found')

	local java_test_item = java_test_items[1]
	local closest_item = self.load_lookup(data.id, java_test_item)

	assert(closest_item, 'No test items found')
	log.debug('closest_item', vim.inspect(closest_item))
	self.context:append_test_item(data.id, closest_item)

	local test_names
	if self.context.test_kind == TestKind.TestNG then
		test_names = { closest_item.fullName }
	else
		test_names = { closest_item.jdtHandler }
	end

	return {
		projectName = closest_item.projectName,
		testLevel = TestLevel.Method,
		testKind = closest_item.testKind,
		testNames = test_names,
	}
end

function BaseRunner:find_all_children(java_test_item)
	if not java_test_item.children then
		return nil
	end
	for _, children in ipairs(java_test_item.children) do
		local neotest_id = BaseRunner.test_item_to_neotest_id(children)
		-- log.error(neotest_id)
		self.context:append_test_item(neotest_id, children)
		self:find_all_children(children)
	end
end

---@private
function BaseRunner:base_handle_file(test_file_uri)
	local java_test_items = self.get_java_test_item(test_file_uri)
	if not java_test_items or #java_test_items == 0 then
		log.info('No test items found')
		return nil
	end

	local java_test_item = java_test_items[1]
	self:find_all_children(java_test_item)
	return java_test_item
end

--- @return JunitLaunchRequestArguments|nil
function BaseRunner:handle_dir(tree)
	local items = {}
	local project_name = nil
	local test_kind = nil
	for _, node in tree:iter_nodes() do
		local node_data = node:data()
		if node_data.type == 'file' or node_data.type == 'namespace' then
			local uri = vim.uri_from_fname(node_data.path)
			local java_test_item = self:base_handle_file(uri)
			if java_test_item ~= nil then
				table.insert(items, java_test_item.fullName)
				if project_name == nil then
					project_name = java_test_item.projectName
				end
				if test_kind == nil then
					test_kind = java_test_item.testKind
				end
			end
		end
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
function BaseRunner:handle_file(test_file_uri)
	local java_test_item = self:base_handle_file(test_file_uri)
	if java_test_item == nil then
		return nil
	end
	return {
		projectName = java_test_item.projectName,
		testLevel = TestLevel.Class,
		testKind = java_test_item.testKind,
		testNames = { vim.split(java_test_item.fullName, '#')[1] },
	}
end

function BaseRunner:shutdown_server()
	if self.server then
		self.server:shutdown()
		self.server:close()
		log.debug('server closed')
	end
end

function BaseRunner:run_test(dap_launcher_config)
	local event = nio.control.event()
	nio.run(function()
		require('dap').run(dap_launcher_config, {
			after = function(_)
				self:shutdown_server()
				event.set()
			end,
		})
	end)
	event.wait()
end

---@param test_file_uri string
---@return JunitLaunchRequestArguments|nil
function BaseRunner:resolve_junit_launch_arguments(tree, test_file_uri)
	local data = tree:data()
	---@type JunitLaunchRequestArguments|nil
	local arguments
	if data.type == 'test' then
		log.debug('type: test')
		arguments = self:handle_test(data, test_file_uri)
	elseif data.type == 'dir' then
		log.debug('type: dir')
		arguments = self:handle_dir(tree)
	elseif data.type == 'file' or data.type == 'namespace' then
		log.debug('type: file')
		arguments = self:handle_file(test_file_uri)
	else
		error('Unsupported type: ' .. data.type)
	end
	if not arguments then
		return nil
	end
	self.context.test_kind = arguments.testKind
	self.context.project_name = arguments.projectName
	return jdtls.get_junit_launch_arguments(arguments)
end

-- luacheck: ignore
--- @param launch_arguments JunitLaunchRequestArguments
--- @param is_debug boolean
--- @param executable string
--- @return table
function BaseRunner:get_dap_launcher_config(
	launch_arguments,
	is_debug,
	executable
)
	error('Not implemented')
end

-- luacheck: ignore
-- @return BaseParser
function BaseRunner:get_result_parser()
	error('Not implemented')
end

function BaseRunner:run(args)
	local strategy = args.strategy
	local tree = args and args.tree
	local data = tree:data()
	local test_file_uri = vim.uri_from_fname(data.path)

	local launch_arguments =
		self:resolve_junit_launch_arguments(tree, test_file_uri)
	assert(
		launch_arguments and launch_arguments.testKind ~= TestKind.None,
		'Unsupported test kind'
	)
	self.test_kind = launch_arguments.testKind

	log.debug('junit_launch_arguments', vim.inspect(launch_arguments))
	if not launch_arguments then
		return {
			context = {
				file = data.path,
				pos_id = data.id,
				type = data.type,
			},
		}
	end

	local is_debug = strategy == 'dap'
	local executable = jdtls.resolve_java_executable(
		launch_arguments.mainClass,
		launch_arguments.projectName
	)

	log.debug('test_context', vim.inspect(self.context))
	local parser = assert(self:get_result_parser(), 'parser is nil') -- Report(self:get_result_parser())
	self.server = assert(vim.loop.new_tcp(), 'uv.new_tcp() must return handle')
	self:setup(parser)

	local dap_launcher_config =
		self:get_dap_launcher_config(launch_arguments, is_debug, executable)

	local config = {}
	if not is_debug then
		-- TODO implement console for non-debug mode
		-- local dapui       = require('dapui')
		-- local console_buf = dapui.elements.console.buffer()
		self:run_test(dap_launcher_config)
	else
		dap_launcher_config.after = function()
			nio.run(function()
				self:shutdown_server()
			end)
		end
		config = dap_launcher_config
	end
	local response = {
		context = {
			report = function()
				return parser:get_mapped_result()
			end,
		},
		strategy = config,
	}
	return response
end

return BaseRunner
