local neotest = require('neotest-jdtls')

describe('is_test_file', function()
	it('return=true', function()
		local files = {
			'src/test/java/mock/MockTest.java',
			'src/test/java/mock/MockRepositoryTest.java',
		}

		for _, file in ipairs(files) do
			assert.is_true(neotest.is_test_file(file))
		end
	end)

	it('return=false', function()
		local files = {
			'src/main/java/mock/Mocktest.java',
			'src/main/java/mock/MockRepository.java',
			'resources/application.properties',
			'pom.xml',
		}

		for _, file in ipairs(files) do
			assert.is_false(neotest.is_test_file(file))
		end
	end)
end)
