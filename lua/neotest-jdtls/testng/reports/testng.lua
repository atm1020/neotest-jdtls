
local class = require('neotest-jdtls.utils.class')
local log = require('neotest-jdtls.utils.log')
local ResultParserFactory =
	require('neotest-jdtls.testng.results.result-parser-factory')

---@class java_test.TestNGTestReport
---@field private conn uv_tcp_t
---@field private result_parser java_test.TestParser
---@field private result_parser_fac java_test.TestParserFactory
local TestNGReport = class()

function TestNGReport:_init()
	self.conn = nil
	self.result_parser_fac = ResultParserFactory()
end

---Returns the test results
---@return java_test.TestResults[]
function TestNGReport:get_results()
	return self.result_parser:get_test_details()
end

---Returns a stream reader function
---@param conn uv_tcp_t
---@return fun(err: string, buffer: string) # callback function
function TestNGReport:get_stream_reader(conn)
	self.conn = conn
	self.result_parser = self.result_parser_fac:get_parser()
	self.result_parser = self.result_parser_fac:get_parser()
	local buffer_loop = function ()
		local buffer = ""
		return function(err, chunk)
			if err then
				self.conn:close()
				return
			end

			if chunk then
				buffer = buffer .. chunk
			else
				self:on_update(buffer)
				self.conn:close()
			end
		end
	end
	return vim.schedule_wrap(buffer_loop())
end


---Runs on connection update
---@private
---@param text string
function TestNGReport:on_update(text)
	log.debug('testng on_update', text)
	self.result_parser:parse(text)
end

return TestNGReport
