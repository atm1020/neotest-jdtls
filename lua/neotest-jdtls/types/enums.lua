local M = {}

---@enum TestKind
M.TestKind = {
	JUnit5 = 0,
	JUnit = 1,
	TestNG = 2,
	None = 100,
}

---@enum TestLevel
M.TestLevel = {
	Workspace = 1,
	WorkspaceFolder = 2,
	Project = 3,
	Package = 4,
	Class = 5,
	Method = 6,
}

--- @enum neotest.TestStatus
M.TestStatus = {
	Failed = 'failed',
	Skipped = 'skipped',
	Passed = 'passed',
}

return M
