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
  if old == new then
    return false
  end
  self.flows[new] = self.flows[old]
  self.flows[old] = nil
  return true
end

---@param name string
function MarksManager:getFlow(name)
  return self.flows[name]
end

--- @return table<string, DumpedMark[]>
function MarksManager:dumps()
  local dumpedTable = {}
  for name, flow in pairs(self.flows) do
    dumpedTable[name] = flow:dumps()
  end
  return dumpedTable
end

---@param dumpedManager table<string, DumpedMark[]>
---@return MarksManager
function MarksManager:loads(dumpedManager)
  local manager = MarksManager:new()
  for name, marks in pairs(dumpedManager) do
    manager.flows[name] = Flow:loads(marks)
  end
  manager.isDirty = false
  return manager
end

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
