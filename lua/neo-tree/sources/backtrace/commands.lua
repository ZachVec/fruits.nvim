local manager = require("neo-tree.sources.manager")
local inputs = require("neo-tree.ui.inputs")
local actions = require("neo-tree.sources.backtrace")

local M = {}

---@param state neotree.StateWithTree
function M.refresh(state)
  vim.print(vim.inspect(state))
  manager.refresh("example", state)
end

---@param state neotree.StateWithTree
---@diagnostic disable-next-line: unused-local
function M.add(state)
  inputs.input("Enter flow name", nil, function(flowName)
    if not flowName then
      return
    end
    if not actions:addFlow(flowName) then
      vim.notify(string.format("Flow %s already exists.", flowName), vim.log.levels.WARN)
    end
  end)
end

---@param state neotree.StateWithTree
function M.delete(state)
  ---@diagnostic disable-next-line: undefined-field
  local node = assert(state.tree:get_node())
  local type = node.type
  local message = string.format("Confirm delete %s?", type)
  inputs.confirm(message, function(confirmed)
    if not confirmed then
      return
    end
    if node.type == "flow" then
      actions:delFlow(node.name)
    elseif node.type == "mark" then
      ---@diagnostic disable-next-line: undefined-field
      local parent = assert(state.tree:get_node(assert(node:get_parent_id())))
      local flow = parent.name
      local ind = vim.split(node.id, ".", { plain = true, trimempty = true })
      table.remove(ind, 1)
      assert(#ind == 1)
      actions:delMark(flow, assert(tonumber(ind[1])))
    end
  end)
end

------@param state neotree.StateWithTree
------@diagnostic disable-next-line: unused-local
---function M.selFlow(state) end

------@param state neotree.StateWithTree
------@diagnostic disable-next-line: unused-local
---function M.addMark(state) end

---@param state neotree.StateWithTree
function M.rename(state)
  ---@diagnostic disable-next-line: undefined-field
  local node = assert(state.tree:get_node())
  local msg = string.format("rename %s from %s to what?", node.type, node.name)
  inputs.input(msg, nil, function(name)
    if not name then
      return
    end
    if node.type == "flow" then
      actions:renameFlow(node.name, name)
    elseif node.type == "name" then
      ---@diagnostic disable-next-line: undefined-field
      local parent = assert(state.tree:get_node(assert(node:get_parent_id())))
      local flow = parent.name
      local ind = vim.split(node.id, ".", { plain = true, trimempty = true })
      table.remove(ind, 1)
      assert(#ind == 1)
      actions:modMark(flow, assert(tonumber(ind[1])), name)
    end
  end)
end

local cc = require("neo-tree.sources.common.commands")
cc._add_common_commands(M)

return M
