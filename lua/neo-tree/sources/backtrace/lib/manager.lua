local Flow = require("neo-tree.sources.backtrace.lib.flow")

---@class MarksManager
--- @field isDirty boolean
--- @field flows table<string, Flow>
local MarksManager = {}

function MarksManager:new()
  return setmetatable({
    isDirty = true,
    flows = {},
  }, { __index = MarksManager })
end

---@param name string
function MarksManager:addFlow(name)
  if self.flows[name] ~= nil then
    return false
  end
  self.flows[name] = Flow:new()
  return true
end

---@param name string
function MarksManager:delFlow(name)
  if self.flows[name] == nil then
    return false
  end
  self.flows[name] = nil
  return true
end

---@param old string
---@param new string
function MarksManager:renameFlow(old, new)
  self.flows[new] = self.flows[old]
  self.flows[old] = nil
end

---@param name string
function MarksManager:getFlow(name)
  return self.flows[name]
end

function MarksManager:dumps()
  local dumpedTable = {}
  for name, flow in pairs(self.flows) do
    dumpedTable[name] = flow:getMarks()
  end
  return vim.json.encode(dumpedTable)
end

---@param str string
function MarksManager:loads(str)
  local manager = MarksManager:new()
  local dumpedTable = vim.json.decode(str)
  for name, marks in pairs(dumpedTable) do
    vim.iter(marks):each(function(mark)
      manager:addMark(name, mark)
    end)
  end
  manager.isDirty = false
  return manager
end

--- @class Node
---  @field id string
---  @field name string
---  @field type string
---  @field children? Node[]

function MarksManager:toNode()
  --- @param index integer
  --- @param name string
  --- @param flow Flow
  local function flowToNode(index, name, flow)
    return flow:toNode(tostring(index), name)
  end
  return vim.iter(vim.spairs(self.flows)):enumerate():map(flowToNode):totable()
end

return MarksManager
