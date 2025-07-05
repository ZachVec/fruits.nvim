local MARK = require("neo-tree.sources.backtrace.lib.mark")

---@class Flow
--- @field marks Mark[]
local Flow = {}

function Flow:new()
  return setmetatable({
    marks = {},
  }, { __index = Flow })
end

--- Add mark into this control flow
---@overload fun(mark: Mark, pos: integer)
---@overload fun(mark: Mark)
---@param mark Mark the mark to be added into this flow
---@param pos integer?
function Flow:addMark(mark, pos)
  table.insert(self.marks, pos or (#self.marks + 1), mark)
end

---@param index integer
function Flow:delMark(index)
  table.remove(self.marks, index)
end

---@param id1 integer
---@param id2 integer
function Flow:swapMark(id1, id2)
  self.marks[id1], self.marks[id2] = self.marks[id2], self.marks[id1]
end

---@param index integer
function Flow:getMark(index)
  return self.marks[index]
end

---@param id string
---@param name string
---@param is_selected boolean
function Flow:toNode(id, name, is_selected)
  ---@param index integer
  ---@param mark Mark
  local function toNode(index, mark)
    return mark:toNode(id .. "." .. tostring(index))
  end
  return {
    id = id,
    name = name,
    type = "flow",
    children = vim.iter(ipairs(self.marks)):map(toNode):totable(),
    extra = {
      is_selected = is_selected,
    },
  }
end

---@return DumpedMark[]
function Flow:dumps()
  return vim.iter(self.marks):map(MARK.dumps):totable()
end

---@param dumped DumpedMark[]
function Flow:loads(dumped)
  local ret = Flow:new()
  ret.marks = vim.iter(dumped):map(MARK.loads):totable()
  return ret
end

return Flow
