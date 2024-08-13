local nio = require('nio')
local adapter = {}

---@class neotest.Adapter
---@field name string
adapter.Adapter = { name = 'neotest-jdtls' }

---Find the project root directory given a current directory to work from.
---Should no root be found, the adapter can still be used in a non-project context if a test file matches.
---@async
---@param dir string @Directory to treat as cwd
---@return string | nil @Absolute root dir of test suite
function adapter.Adapter.root(dir)
	return require('neotest-jdtls.neotest.impl.root').root(dir)
end

---Filter directories when searching for test files
---@async
---@param name string Name of directory
---@param rel_path string Path to directory, relative to root
---@param root string Root directory of project
---@return boolean
function adapter.Adapter.filter_dir(name, rel_path, root)
	nio.scheduler()
	return require('neotest-jdtls.neotest.impl.filter_dir').filter_dir(
		name,
		rel_path,
		root
	)
end

---@async
---@param file_path string
---@return boolean
function adapter.Adapter.is_test_file(file_path)
	nio.scheduler()
	local is_test_file =
		require('neotest-jdtls.neotest.impl.is_test_file').is_test_file(file_path)
	return is_test_file
end

---Given a file path, parse all the tests within it.
---@async
---@param file_path string Absolute file path
---@return neotest.Tree | nil
function adapter.Adapter.discover_positions(file_path)
	return require('neotest-jdtls.neotest.impl.discover_positions').discover_positions(
		file_path
	)
end

---@param args neotest.RunArgs
---@return neotest.RunSpec
function adapter.Adapter.build_spec(args)
	return require('neotest-jdtls.neotest.impl.excute').build_spec(args)
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
function adapter.Adapter.results(spec, result, tree)
	return require('neotest-jdtls.neotest.impl.results').results(
		spec,
		result,
		tree
	)
end

return adapter.Adapter
