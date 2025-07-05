local Flow = require("neo-tree.sources.backtrace.lib.flow")

---@class MarksManager
--- @field mDirty boolean
--- @field mFlows table<string, Flow>
local MarksManager = {

  ---@param self MarksManager
  ---@return string[]
  flows = function(self)
    return vim.tbl_keys(self.mFlows)
  end,

  ---@param self MarksManager
  ---@return boolean
  getIsDirty = function(self)
    return self.mDirty
  end,

  ---@param self MarksManager
  ---@param dirty boolean
  setIsDirty = function(self, dirty)
    self.mDirty = dirty
  end,

  ---@param self MarksManager
  ---@return integer
  size = function(self)
    return vim.tbl_count(self.mFlows)
  end,

  ---@param self MarksManager
  ---@return boolean
  empty = function(self)
    return self:size() == 0
  end,

  ---@param self MarksManager
  ---@param selected_flow string?
  toNode = function(self, selected_flow)
    --- @param index integer
    --- @param name string
    --- @param flow Flow
    local function flowToNode(index, name, flow)
      return flow:toNode(tostring(index), name, name == selected_flow)
    end
    return vim.iter(vim.spairs(self.mFlows)):enumerate():map(flowToNode):totable()
  end,
}

function MarksManager:new()
  return setmetatable({
    mDirty = true,
    mFlows = {},
  }, { __index = MarksManager })
end

--- @return table<string, DumpedMark[]>
function MarksManager:dumps()
  local dumpedTable = {}
  for name, flow in pairs(self.mFlows) do
    dumpedTable[name] = flow:dumps()
  end
  return dumpedTable
end

---@param dumpedManager table<string, DumpedMark[]>
---@return MarksManager
function MarksManager:loads(dumpedManager)
  local manager = MarksManager:new()
  for name, marks in pairs(dumpedManager) do
    manager.mFlows[name] = Flow:loads(marks)
  end
  manager.mDirty = false
  return manager
end

---@param name string
function MarksManager:addFlow(name)
  if self.mFlows[name] ~= nil then
    return false
  end
  self.mFlows[name] = Flow:new()
  return true
end

---@param name string
function MarksManager:delFlow(name)
  if self.mFlows[name] == nil then
    return false
  end
  self.mFlows[name] = nil
  return true
end

---@param old string
---@param new string
function MarksManager:modFlow(old, new)
  if old == new then
    return false
  end
  self.mFlows[new] = self.mFlows[old]
  self.mFlows[old] = nil
  return true
end

---@param name string
function MarksManager:getFlow(name)
  return self.mFlows[name]
end

return MarksManager
