
local class = require('neotest-jdtls.utils.class')
local log = require('neotest-jdtls.utils.log')
local BaseParser = require('neotest-jdtls.utils.base_parser')

---@class java_test.TestNGTestParser : BaseParser
---@field private test_details java_test.TestResults[]
local TestNGTestParser = class(BaseParser)

---@param context TestContext
function TestNGTestParser:_init(context)
	-- self:super()
	self.context = context
	self.test_details = {}
	self.lookup = {}
	self.results = {}
end

local function parse(content)
  local lines = vim.split(content, '\n')
  for _, line in ipairs(lines) do
    if vim.startswith(line, '@@<TestRunner-') then
      line = line.sub(line, 15)
      line = line:sub(1, -13)
      local test = vim.json.decode(line)
      if test.name ~= 'testStarted' then
          return test
      end
    end
  end
  return nil
end


---Parse a given text into test details
---@param text string test result buffer
function TestNGTestParser:on_update(text)
    local parsedResult = parse(text)
    if parsedResult == nil then
		log.info("Could not parse result.", text)
        return;
    end
    local testName = parsedResult["attributes"]["name"]
    local test = vim.split(testName, "#")
    local testPathElements = vim.split(test[1], "%.")
    local testFile = testPathElements[#testPathElements]
    local testMethodName = test[2]:sub(1,-3)
	local testId = vim.fn.expand("src/**/" .. test[1]:gsub("%.","/") .. ".java")
	testId = vim.fn.getcwd() .. "/" .. testId .. "::" .. testFile .. "::" .. testMethodName

    local status = parsedResult["name"]
	local repl = require('dap.repl')
    if status == 'testFailed' then
		local msg = parsedResult["attributes"]["message"] or 'test failed'
		local trace = parsedResult["attributes"]["trace"]
        self.results[testId] = {
            status = "failed",
            short = msg,
            errors = {
                {
                    message = trace,
                }
            },
        }
		if repl ~= nil then
			repl.append(' ' .. testName .. ' failed')
			repl.append(msg)
			repl.append(trace)
		end
    elseif status == 'testFinished' then
        self.test_details.results[testId] = {
            status = "passed",
        }
		if repl ~= nil then
			repl.append(' ' .. testName .. ' passed')
		end
	else
		log.warn("Unknown test status: ", parsedResult["name"])
    end
end

---@class java_test.TestResultExecutionDetails
---@field actual string[] lines
---@field expected string[] lines
---@field status java_test.TestExecStatus
---@field execution java_test.TestExecutionStatus
---@field trace string[] lines

---@class java_test.TestResults
---@field display_name string
---@field is_dynamic_test boolean
---@field is_suite boolean
---@field parameter_types string
---@field parent_id integer
---@field test_count integer
---@field test_id integer
---@field test_name string
---@field unique_id string
---@field result java_test.TestResultExecutionDetails
---@field children java_test.TestResults[]

return TestNGTestParser
