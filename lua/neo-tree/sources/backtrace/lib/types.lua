---@class BacktraceNode.Extra
--- @field bufnr integer? Mark extra
--- @field position integer[]? Mark extra, size of 2, indexed by 1
--- @field selected boolean? Flow extra

---@class BacktraceNode
--- @field id string
--- @field name string
--- @field type string
--- @field path string
--- @field children BacktraceNode[]
--- @field extra BacktraceNode.Extra

---@class BacktraceDumpedMark
--- @field path string
--- @field lnum integer
--- @field cnum integer
--- @field symbol string?
--- @field custom string?
