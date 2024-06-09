local neotest = require('neotest-jdtls')

describe('filter_dir', function()
	local root = '/home/user/workspace/demo'
	it('return=true', function()
		local dirs = {
			{ 'test', 'test', root },
			{ 'src', 'src/test/java/com/example', root },
			{ 'src', 'module2/src', root },
		}

		for _, dir in ipairs(dirs) do
			assert.is_true(neotest.filter_dir(dir[1], dir[2], dir[3]))
		end
	end)
	it('return=false', function()
		local dirs = {
			{ 'target', 'target', root },
			{ 'src', 'src/main/java/com/example', root },
		}
		for _, dir in ipairs(dirs) do
			assert.is_false(neotest.filter_dir(dir[1], dir[2], dir[3]))
		end
	end)
end)
