local class = require('neotest-jdtls.utils.class')
local log = require('neotest-jdtls.utils.log')

---@class BaseParser
local BaseParser = class()

---Returns a stream reader function
---@param conn uv_tcp_t
---@return fun(err: string, buffer: string) # callback function
function BaseParser:get_stream_reader(conn)
	self.conn = conn
	return vim.schedule_wrap(function(err, buffer)
		if err then
			self.conn:close()
			return
		end

		if buffer then
			log.debug('buffer', buffer)
			self:on_update(buffer)
		else
			self.conn:close()
			log.debug('connection closed')
		end
	end)
end

-- luacheck: ignore
---Runs on connection update
---@protected
---@param text string
function BaseParser:on_update(text)
	error('Not implemented')
end

---@protected
--- @return  table<string, neotest.Result>
function BaseParser:get_mapped_result()
	error('Not implemented')
end

return BaseParser
