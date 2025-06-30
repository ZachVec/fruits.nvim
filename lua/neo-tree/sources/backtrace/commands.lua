local inputs = require("neo-tree.ui.inputs")
local actions = require("neo-tree.sources.backtrace.lib.actions")
local navigate = require("neo-tree.sources.backtrace").navigate

local M = {}

---@param state neotree.StateWithTree
---@diagnostic disable-next-line: unused-local
function M.refresh(state)
  navigate(state)
end

---@param state neotree.StateWithTree
function M.add_flow(state)
  inputs.input("Enter flow name", nil, function(flowName)
    if not flowName then
      return
    end
    if not actions:add_flow(flowName) then
      vim.notify(("Flow %s already exists."):format(flowName), vim.log.levels.WARN)
      return
    end
    navigate(state)
  end)
end

---@param state neotree.StateWithTree
function M.delete(state)
  ---@diagnostic disable-next-line: undefined-field
  local node = assert(state.tree:get_node())
  local type = node.type
  local message = ("Confirm delete %s?"):format(type)
  inputs.confirm(message, function(confirmed)
    if not confirmed then
      return
    end
    if node.type == "flow" then
      actions:del_flow(node.name)
    elseif node.type == "mark" then
      ---@diagnostic disable-next-line: undefined-field
      local parent = assert(state.tree:get_node(assert(node:get_parent_id())))
      local flow = parent.name
      local ind = vim.split(node.id, ".", { plain = true, trimempty = true })
      table.remove(ind, 1)
      assert(#ind == 1)
      actions:del_mark(flow, assert(tonumber(ind[1])))
    end
    navigate(state)
  end)
end

---@param state neotree.StateWithTree
function M.rename(state)
  ---@diagnostic disable-next-line: undefined-field
  local node = assert(state.tree:get_node())
  local msg = ("rename %s from %s to what?"):format(node.type, node.name)
  inputs.input(msg, nil, function(name)
    if not name then
      return
    end
    if node.type == "flow" then
      actions:mod_flow(node.name, name)
    elseif node.type == "name" then
      ---@diagnostic disable-next-line: undefined-field
      local parent = assert(state.tree:get_node(assert(node:get_parent_id())))
      local flow = parent.name
      local ind = vim.split(node.id, ".", { plain = true, trimempty = true })
      table.remove(ind, 1)
      assert(#ind == 1)
      actions:mod_mark(flow, assert(tonumber(ind[1])), name)
    end
    navigate(state)
  end)
end

local cc = require("neo-tree.sources.common.commands")
cc._add_common_commands(M, "^show_help$")
cc._add_common_commands(M, "^cancel$")
cc._add_common_commands(M, "^close_window$")

cc._add_common_commands(M, "nodes?$")
cc._add_common_commands(M, "^open")
cc._add_common_commands(M, "source$")
cc._add_common_commands(M, "preview$")
cc._add_common_commands(M, "^toggle")

return M
