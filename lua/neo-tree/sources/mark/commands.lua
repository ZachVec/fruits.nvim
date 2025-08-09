--- @class neotree.sources.mark.Commands
--- @field [string] neotree.TreeCommand
local M = {}

local Mark = require("neo-tree.sources.mark")
local inputs = require("neo-tree.ui.inputs")
local cc = require("neo-tree.sources.common.commands")
local renderer = require("neo-tree.ui.renderer")
local events = require("neo-tree.events")

function M.refresh(state)
  if renderer.window_exists(state) then
    Mark.navigate(state)
  end
end

function M.create_flow(state)
  inputs.input("Enter flow name", nil, function(name)
    if not name then
      return
    end
    if not Mark.mark:create_flow(name) then
      vim.notify(("Flow %s already exists."):format(name), vim.log.levels.WARN)
      return
    end
    events.fire_event("after_modify_tree", state)
  end)
end

function M.select_flow(state)
  local success, node = pcall(state.tree.get_node, state.tree)
  if not (success and node) then
    vim.notify("Could not get node.", vim.log.levels.WARN)
    return
  end
  if node.type == "mark" then
    node = assert(state.tree:get_node(node:get_parent_id()))
  end
  local prev, curr = Mark.flow, node
  Mark.flow = node
  events.fire_event("after_select_flow", { state = state, prev = prev, curr = curr })
end

function M.delete_item(state)
  local success, node = pcall(state.tree.get_node, state.tree)
  if not (success and node) then
    vim.notify("Could not get node.", vim.log.levels.WARN)
    return
  end
  local type = node.type == "mark" and "mark" or "flow"
  inputs.confirm(("Confirm delete %s?"):format(type), function(confirmed)
    if not confirmed then
      return
    end
    if node.type == "directory" then
      if node.extra.selected then
        Mark.flow = nil
      end
      assert(Mark.mark:remove_flow(node.name))
      events.fire_event("after_modify_tree", state)
    elseif node.type == "mark" then
      local splits = vim.split(node.id, ".", { plain = true, trimempty = true })
      local index = assert(tonumber(splits[#splits]))
      local flow = assert(state.tree:get_node(assert(node:get_parent_id()))).name
      assert(Mark.mark:remove_mark(flow, index))
      events.fire_event("after_modify_tree", state)
    else
      assert(false, ("Unknown node type %s"):format(node.type))
    end
  end)
end

function M.rename_item(state)
  local success, node = pcall(state.tree.get_node, state.tree)
  if not (success and node) then
    vim.notify("Could not get node.", vim.log.levels.WARN)
    return
  end
  inputs.input(("rename %s from '%s' to:"):format(node.type, node.name), nil, function(name)
    if not name then
      return
    end
    if node.type == "directory" then
      assert(Mark.mark:rename_flow(node.name, name))
      events.fire_event("after_modify_tree", state)
    elseif node.type == "mark" then
      local splits = vim.split(node.id, ".", { plain = true, trimempty = true })
      local index = assert(tonumber(splits[#splits]))
      local flow = assert(state.tree:get_node(assert(node:get_parent_id()))).name
      assert(Mark.mark:rename_mark(flow, index, name))
      events.fire_event("after_modify_tree", state)
    else
      assert(false, ("Unknown node type %s"):format(node.type))
    end
  end)
end

function M.debug(state)
  local success, node = pcall(state.tree.get_node, state.tree)
  if not (success and node) then
    vim.notify("Could not get node.", vim.log.levels.WARN)
    return
  end
  vim.notify(vim.inspect(node), vim.log.levels.INFO)
end

--- @type fun(fn: neotree.TreeCommand): neotree.TreeCommand
local function prepare_node(fn)
  --- @param state neotree.StateWithTree
  local function decorated(state, ...)
    local success, node = pcall(state.tree.get_node, state.tree)
    if not (success and node) then
      vim.notify("Could not get node.", vim.log.levels.WARN)
      return
    end

    if node.type == "mark" then
      --- @type { bufnr: integer, ns_id: integer, markid: integer } | nil
      local mark = node.extra.mark
      if mark ~= nil then
        node.extra.position =
          vim.api.nvim_buf_get_extmark_by_id(mark.bufnr, mark.ns_id, mark.markid, {
            details = false,
          })
      end
    end

    return fn(state, ...)
  end

  return decorated
end

M.preview = prepare_node(cc.preview)

cc._add_common_commands(M, "^open")
cc._add_common_commands(M, "^show_help$")
cc._add_common_commands(M, "^cancel$")
cc._add_common_commands(M, "^close_window$")
cc._add_common_commands(M, "nodes?$")
cc._add_common_commands(M, "source$")
cc._add_common_commands(M, "preview$")
cc._add_common_commands(M, "^toggle")

return M
