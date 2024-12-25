local JunitRunner = require('neotest-jdtls.junit.runner')
local test_case = require('tests.junit.test_case.runner_test_case')
local test_name_format = require('tests.utils').test_name_format

describe('JunitRunner:', function()
	it('test_id_to_neotest_id: ', function()
		local casaes = test_case.test_id_to_neotest_id()
		for _, case in ipairs(casaes) do
			it(test_name_format(case.expected, case.input.id), function()
				local result = JunitRunner.test_item_to_neotest_id(case.input)
				assert.equals(case.expected, result)
			end)
		end
	end)
end)
