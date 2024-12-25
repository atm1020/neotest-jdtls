--- @class JunitLaunchRequestArguments
--- @field projectName string
--- @field mainClass string
--- @field testLevel number
--- @field testKind TestKind
--- @field testNames string[]

---@class ResolvedMainClass
---@field mainClass string
---@field projectName string

---@class JavaTestItem
---@field children JavaTestItem[]
---@field uri string
---@field range Range
---@field jdtHandler string
---@field fullName string
---@field label string
---@field id string
---@field projectName string
---@field testKind TestKind
---@field testLevel TestLevel
---@field sortText string
---@field uniqueId string
---@field natureIds string[]
---
---@class Range
---@field start Position
---@field end Position

---@class Position
---@field line number
---@field character number