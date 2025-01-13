local jdtls = require('neotest-jdtls.utils.jdtls')
local class = require('neotest-jdtls.utils.class')
local log = require('neotest-jdtls.utils.log')
local TestRunner = require('neotest-jdtls.utils.base_runner')
local TestNGTestParser = require('neotest-jdtls.junit.result_parser')

---@class TestNGRunner : BaseRunner
local TestNGRunner = class(TestRunner)

function TestNGRunner:_init()
	self:super()
end

local get_clients = vim.lsp.get_clients or vim.lsp.get_active_clients
local function testng_runner()
  local bundles = {}
  local mason_path = vim.fn.glob(vim.fn.stdpath "data" .. "/mason/")
  vim.list_extend(bundles, vim.split(vim.fn.glob(mason_path .. "packages/java-test/extension/server/*.jar"), "\n"))

  local vscode_runner = 'com.microsoft.java.test.runner-jar-with-dependencies.jar'

  -- TODO check more locations
  local client = get_clients({name='jdtls'})[1]
  local bundles = client and client.config.init_options.bundles or {}

  for _, jar_path in pairs(bundles) do
    local parts = vim.split(jar_path, '/')
    if parts[#parts] == vscode_runner then
      return jar_path
    end
    local basepath = vim.fs.dirname(jar_path)
    if basepath then
      for name, _ in vim.fs.dir(basepath) do
        if name == vscode_runner then
          return vim.fs.joinpath(basepath, name)
        end
      end
    end
  end
  assert(false, "This project requires the 'com.microsoft.java.test.runner-jar-with-dependencies.jar' to run TestNG tests. If you are using Mason, try installing the java-test package.")
end

local function merge_unique(xs, ys)
  local result = {}
  local seen = {}
  local both = {}
  vim.list_extend(both, xs or {})
  vim.list_extend(both, ys or {})

  for _, x in pairs(both) do
    if not seen[x] then
      table.insert(result, x)
      seen[x] = true
    end
  end

  return result
end
--- @param launch_arguments JunitLaunchRequestArguments
--- @param is_debug boolean
--- @param executable string
--- @return table
function TestNGRunner:get_dap_launcher_config(
	launch_arguments,
	is_debug,
	executable
)

    local jar = testng_runner()
    launch_arguments.mainClass = 'com.microsoft.java.test.runner.Launcher'
    launch_arguments.programArguments = self.context.test_names
    table.insert(launch_arguments.programArguments, 1, "testng")

    local options = vim.fn.json_encode({ scope = 'test'; })
    local cmdArguments = { vim.uri_from_bufnr(0), options };
    local res = jdtls.get_class_paths(cmdArguments)
    launch_arguments.classpath = merge_unique(launch_arguments.classpath, res.classpath)
    table.insert(launch_arguments.classpath, jar);

	local dap_launcher_config

	dap_launcher_config =
		self.get_base_dap_launcher_config(launch_arguments, executable,  {
                debug = is_debug,
                label = 'Launch TestNG test(s)',
        })
    dap_launcher_config.args = string.format('%s %s', self.server:getsockname().port, dap_launcher_config.args)
	log.debug('dap_launcher_config', vim.inspect(dap_launcher_config))
	return dap_launcher_config
end

function TestNGRunner:get_result_parser()
	assert(self.context.test_kind, 'test_kind is nil')
	return TestNGTestParser(self.context)
end
return TestNGRunner
