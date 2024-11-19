local lib = require('neotest.lib')

local M = {}

M.discover_positions = function(file_path)
	-- https://github.com/rcasia/neotest-java/blob/main/lua/neotest-java/core/positions_discoverer.lua
	local query = [[
	      ;; Test class
		(class_declaration
		  name: (identifier) @namespace.name
		) @namespace.definition

	      ;; @Test and @ParameterizedTest functions
	      (method_declaration
		(modifiers
		  (marker_annotation
		    name: (identifier) @annotation
		      (#any-of? @annotation "Test" "ParameterizedTest" "CartesianTest")
		    )
		)
		name: (identifier) @test.name
	      )
	      @test.definition
	      ;;  @ParameterizedTest(xx) functions
	      (method_declaration
		(modifiers
		  (annotation
		    name: (identifier) @annotation
		      (#any-of? @annotation  "ParameterizedTest" )
		    )
		)
		name: (identifier) @test.name
	      )
	      @test.definition

	]]

	return lib.treesitter.parse_positions(
		file_path,
		query,
		{ nested_namespaces = true }
	)
end

return M
