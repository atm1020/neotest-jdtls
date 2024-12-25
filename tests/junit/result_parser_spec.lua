local TestParser = require('neotest-jdtls.junit.result_parser')
local test_name_format = require('tests.utils').test_name_format
local TestKind = require('neotest-jdtls.types.enums').TestKind
local JunitTestParser = require('neotest-jdtls.junit.result_parser')
local test_case = require('tests.junit.test_case.result_parser_test_case')

describe('JunitResultParser', function()
	describe('test_kind: [Junit5]', function()
		local parser = TestParser({
			test_kind = TestKind.JUnit5,
		})

		it('on_update', function()
			for _, case in ipairs(test_case.test_cases_junit5) do
				it(test_name_format(vim.inspect(case.expected), case.input), function()
					parser:on_update(case.input)
					assert.are.same(case.expected, parser.test_details[1])
				end)
			end
		end)
	end)

	local test_cases_junit = {
		{

			input = '%TSTTREE1,testApp(org.zrgs.maven.CopyOfAppTest),false,1,false,-1,testApp(org.zrgs.maven.CopyOfAppTest),,',
			expected = {
				display_name = 'testApp(org.zrgs.maven.CopyOfAppTest)',
				is_dynamic_test = false,
				is_suite = false,
				parent_id = -1,
				test_count = 1,
				test_id = 1,
				test_name = 'testApp(org.zrgs.maven.CopyOfAppTest)',
				unique_id = 'testApp(org.zrgs.maven.CopyOfAppTest)',
			},
		},
	}

	describe('test_kind: [juni4]', function()
		local parser = TestParser({
			test_kind = TestKind.JUnit,
		})

		it('on_update', function()
			for _, case in ipairs(test_cases_junit) do
				it(test_name_format(vim.inspect(case.expected), case.input), function()
					parser:on_update(case.input)
					assert.are.same(case.expected, parser.test_details[1])
				end)
			end
		end)
	end)

	it('get_test_id_for_junit5_method:', function()
		local project_name = 'spring-petclinic'
		local cases = test_case.get_test_id_for_junit_5method(project_name)
		for _, case in ipairs(cases) do
			it(test_name_format(case.expected, case.input), function()
				local result = JunitTestParser.get_test_id_for_junit5_method(
					project_name,
					case.input
				)
				assert.equals(case.expected, result)
			end)
		end
	end)

	it('get_junit5_method_name:', function()
		for _, case in ipairs(test_case.get_junit5_method_name) do
			it(test_name_format(case.expected, case.input), function()
				local result = JunitTestParser.get_junit5_method_name(case.input)
				assert.equals(case.expected, result)
			end)
		end
	end)
end)
