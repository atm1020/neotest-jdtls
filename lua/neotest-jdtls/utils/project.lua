local log = require('neotest-jdtls.utils.log')
local jdtls = require('neotest-jdtls.utils.jdtls')
local TestLevel = require('neotest-jdtls.types.enums').TestLevel
local class = require('neotest-jdtls.utils.class')

local M = {
	project_cache = nil,
}

--- @class ProjectCache
--- @field test_folders table<string, boolean> -- <uri, boolean>
--- @field methods table<string, boolean> -- <uri, boolean>
--- @field root_dir string
--- @field test_kind TestKind
--- @field project_name string
--- @field uri string
local ProjectCache = class()

function ProjectCache:_init(project_name, test_kind, uri)
	assert(project_name)
	assert(test_kind)
	assert(uri)
	self.project_name = project_name
	self.test_kind = test_kind
	self.uri = uri
	self.methods = {}
	self.test_folders = {}
end

--[[ Example:

root : /home/username/project
path : /home/username/project/src/main/java/com/example/Hello.java
test_folders : {}

To fill test_folders:
current : {
	src=true,
	main=true,
	java=true,
	com=true,
	example=true,
	src/main=true,
	src/main/java=true,
	src/main/java/com=true,
	src/main/java/com/example=true}

--]]
--- @param root string
--- @param path string
--- @param test_folders table<string, boolean>
local function split_and_fill(root, path, test_folders)
	local p = vim.uri_to_fname(path):sub(#root + 2)
	local parts = {}
	for dir in p:gmatch('([^/]+)/?') do
		table.insert(parts, dir)
		test_folders[table.concat(parts, '/')] = true
		test_folders[dir] = true
	end
end

local function load_current_project()
	log.debug('Project cache loading')
	local root = jdtls.root_dir()
	local project = jdtls.find_java_projects(root)
	assert(#project == 1, 'Multimodule projects currently not supported')
	local jdtHandler = project[1].jdtHandler
	local cache =
		ProjectCache(project[1].projectName, project[1].testKind, project[1].uri)

	local data = jdtls.find_test_packages_and_types(jdtHandler)
	for _, package in ipairs(data) do
		if
			package.testLevel == TestLevel.Package
			or package.testLevel == TestLevel.Project
		then
			split_and_fill(root, package.uri, cache.test_folders)
			for _, child in ipairs(package.children) do
				split_and_fill(root, package.uri, cache.test_folders)
				if child.testLevel == TestLevel.Class then
					cache.methods[child.uri] = true
				end
			end
		end
	end
	M.project_cache = cache
	log.debug('Project cache loaded')
end

--- @return ProjectCache
function M.get_current_project()
	if not M.project_cache then
		load_current_project()
	end
	return M.project_cache
end

function M.clear_project_cache()
	M.project_cache = nil
	log.debug('Project cache cleared')
end

return M
