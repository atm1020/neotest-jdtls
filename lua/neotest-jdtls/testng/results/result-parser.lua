local class = require('neotest-jdtls.utils.class')
local log = require('neotest-jdtls.utils.log')
local MessageId = require('neotest-jdtls.junit.results.message-id')
local TestStatus = require('neotest-jdtls.junit.results.result-status')
local TestExecStatus = require('neotest-jdtls.junit.results.execution-status')

---@class java_test.TestParser
local TestParser = class()

---Init
---@private
function TestParser:_init()
	self.test_details = {
        testType = 2, -- TestNG
        results = {}
    }
end


---Returns the parsed test details
---@return java_test.TestResults # parsed test details
function TestParser:get_test_details()
	return self.test_details
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
        -- table.insert(tests, test)
      end
      return nil
    end
  end
end

---Parse a given text into test details
---@param text string test result buffer
function TestParser:parse(text)
    local parsedResult = parse(text)
    if parsedResult == nil then
        return;
    end
    local testName = parsedResult["attributes"]["name"]
    local test = vim.split(testName, "#")
    local testPathElements = vim.split(test[1], "%.")
    local testFile = testPathElements[#testPathElements]
    local testMethodName = test[2]:sub(1,-3)
    local testId = test[1]:gsub("%.","/") .. ".java::" .. testFile .. "::" .. testMethodName
    testId = vim.fn.getcwd() .. "/src/test/java/" .. testId
    local status = parsedResult["name"]
    if status == 'testFailed' then
        self.test_details.results[testId] = {
            status = "failed",
            short = parsedResult["attributes"]["message"],
            errors = {
                {
                    message = parsedResult["attributes"]["trace"],
                }
            },
        }
    elseif status == 'testFinished' then
        self.test_details.results[testId] = {
            status = "passed",
        }
    end
    log.warn("Unknown test status: ", parsedResult["name"])
end

return TestParser

---@class java_test.TestResultExecutionDetails
---@field actual string[] lines
---@field expected string[] lines
---@field status java_test.TestStatus
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
