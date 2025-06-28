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

function Flow:getMarks()
  return self.marks
end

---@param id string
---@param name string
function Flow:toNode(id, name)
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
  }
end

function Flow:size()
  return #self.marks
end

return Flow
