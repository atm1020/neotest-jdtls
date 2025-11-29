local jdtls = require('neotest-jdtls.utils.jdtls')
local project = require('neotest-jdtls.utils.project')
local Tree = require('neotest.types.tree')
local TestLevel = require('neotest-jdtls.types.enums').TestLevel

local M = {}

local function get_range(item)
	return {
		item.range.start.line,
		item.range.start.character,
		item.range['end'].line,
		item.range['end'].character,
	}
end

local function build_file_data(item)
	return {
		id = vim.uri_to_fname(item.uri),
		name = vim.fn.fnamemodify(item.uri, ':t'),
		path = vim.uri_to_fname(item.uri),
		range = {
			0,
			0,
			item.range['end'].line,
			0,
		},
		type = 'file',
	}
end

local function build_namespace_data(item)
	return {
		id = item.id,
		name = item.label,
		path = vim.uri_to_fname(item.uri),
		range = get_range(item),
		type = 'namespace',
	}
end

local function build_method_data(item)
	return {
		id = item.id,
		name = item.label:match('(.-)%('),
		path = vim.uri_to_fname(item.uri),
		range = get_range(item),
		type = 'test',
	}
end

local function sort_methods(target)
	table.sort(target, function(a, b)
		local range_a = a.range
		local range_b = b.range
		if not a.range and #a > 0 then
			range_a = a[1].range
		end
		if not b.range and #b > 0 then
			range_b = b[1].range
		end
		return range_a[1] < range_b[1]
	end)
end

local function build_raw_list(item)
	local target = {}
	for _, method in ipairs(item.children) do
		if method.testLevel == TestLevel.Class then
			local ch = build_raw_list(method)
			table.insert(target, ch)
		else
			table.insert(target, build_method_data(method))
		end
	end
	table.insert(target, 1, build_namespace_data(item))
	sort_methods(target)
	return target
end

local id = function(pos)
	return pos.id
end

M.discover_positions = function(file_path)
	if project.project_cache == nil then
		project.get_current_project()
	end

	local path = vim.uri_from_fname(file_path)
	local raw_test_file = project.project_cache.raw_test_file_lookup[path]

	local structure = {}
	table.insert(structure, build_file_data(raw_test_file))
	local node = Tree.from_list(structure, id)

	local java_test_items = jdtls.find_test_types_and_methods(raw_test_file.uri)
	for _, item in ipairs(java_test_items) do
		local target = build_raw_list(item)
		node:add_child(id, Tree.from_list(target, id))
	end

	return node
end

return M
