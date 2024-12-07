local log = require('neotest-jdtls.utils.log')
local nio = require('nio')

local JDTLS = {}

---@enum TestKind
JDTLS.TestKind = {
	JUnit5 = 0,
	JUnit = 1,
	TestNG = 2,
	None = 100,
}

---@enum TestLevel
JDTLS.TestLevel = {
	Workspace = 1,
	WorkspaceFolder = 2,
	Project = 3,
	Package = 4,
	Class = 5,
	Method = 6,
}

function JDTLS.get_client()
	local clients = nio.lsp.get_clients({ name = 'jdtls' })

	if #clients > 1 then
		error('Could not find any running jdtls clients')
	end

	return clients[1]
end

function JDTLS.root_dir()
	-- TODO check why the nio.ls.get_clients is dosent has config property
	local client = vim.lsp.get_clients({ name = 'jdtls' })[1]
	return client.config.root_dir
end

---TODO use this function to execute commands
---@param cmd_info {command: string, arguments: any }
---@return { err: { code: number, message: string }, result: any }
local function execute_command(cmd_info)
	log.trace(
		'Executing command:',
		'[' .. cmd_info.command .. ']',
		'with args:',
		vim.inspect(cmd_info.arguments)
	)
	local err, result = JDTLS.get_client().request
		.workspace_executeCommand(cmd_info)
	if err then
		log.debug(
			'Command',
			'[' .. cmd_info.command .. ']',
			'failed with error:',
			vim.inspect(err)
		)
	else
		log.debug(
			'Command',
			'[' .. cmd_info.command .. ']',
			'executed with result:',
			vim.inspect(result)
		)
	end
	return {
		err = err,
		result = result,
	}
end

--- @param test_file_uri string
--- @return JavaTestItem[]
function JDTLS.find_test_types_and_methods(test_file_uri)
	local response = execute_command({
		command = 'vscode.java.test.findTestTypesAndMethods',
		arguments = { test_file_uri },
	})
	return response.result
end

--- @return JavaTestItem[]
function JDTLS.find_java_projects(root)
	return execute_command({
		command = 'vscode.java.test.findJavaProjects',
		arguments = { vim.uri_from_fname(root) },
	}).result
end

--- @param file_path string
--- @return { err: { code: number, message: string }, result: boolean }
function JDTLS.is_test_file(file_path)
	return execute_command({
		command = 'java.project.isTestFile',
		arguments = { vim.uri_from_fname(file_path) },
	})
end

--- @param jdtHandler string
--- @return JavaTestItem[]
function JDTLS.find_test_packages_and_types(jdtHandler)
	return execute_command({
		command = 'vscode.java.test.findTestPackagesAndTypes',
		arguments = { jdtHandler },
	}).result
end

--- @param arguments JunitLaunchRequestArguments
function JDTLS.get_junit_launch_arguments(arguments)
    local res =
	 execute_command({
		command = 'vscode.java.test.junit.argument',
		arguments = vim.fn.json_encode(arguments),
	})
    return res.result.body
end

--- @param main_class string
--- @param project_name string
function JDTLS.resolve_java_executable(main_class, project_name)
	local response = execute_command({
		command = 'vscode.java.resolveJavaExecutable',
		arguments = {
			main_class,
			project_name,
		},
	}).result
	return response
end
function JDTLS.get_class_paths(args)
    local cmd = {
        command = 'java.project.getClasspaths';
        arguments = args;
    }
	local response = execute_command(cmd).result
	return response
end

return JDTLS

---@class JavaTestItem
---@field children JavaTestItem[]
---@field uri string
---@field range Range
---@field jdtHandler string
---@field fullName string
---@field label string
---@field id string
---@field projectName string
---@field testKind TestKind
---@field testLevel TestLevel
---@field sortText string
---@field uniqueId string
---@field natureIds string[]
---
---@class Range
---@field start Position
---@field end Position

---@class Position
---@field line number
---@field character number
