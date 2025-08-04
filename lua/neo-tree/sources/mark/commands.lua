--- @class neotree.sources.mark.Commands
--- @field public refresh fun(state: neotree.StateWithTree)
--- @field public create_flow fun(state: neotree.StateWithTree)
--- @field public select_flow fun(state: neotree.StateWithTree)
--- @field public delete_item fun(state: neotree.StateWithTree)
--- @field public rename_item fun(state: neotree.StateWithTree)
--- @field public debug fun(state: neotree.StateWithTree)
local M = {}

local Inputs = require("neo-tree.ui.inputs")
local Mark = require("neo-tree.sources.mark")

function M.refresh(state)
  Mark.navigate(state)
end

function M.create_flow(_)
  Inputs.input("Enter flow name", nil, function(name)
    if not name then
      return
    end
    if not Mark.mark:create_flow(name) then
      vim.notify(("Flow %s already exists."):format(name), vim.log.levels.WARN)
      return
    end
  end)
end

function M.select_flow(state)
  local node = assert(state.tree:get_node())
  if node.type ~= "flow" then
    node = assert(state.tree:get_node(node:get_parent_id()))
  end
  Mark.mark:select_flow(node.name)
end

function M.delete_item(state)
  local node = assert(state.tree:get_node())
  Inputs.confirm(("Confirm delete %s?"):format(node.type), function(confirmed)
    if not confirmed then
      return
    end
    if node.type == "flow" then
      assert(Mark.mark:remove_flow(node.name))
    elseif node.type == "mark" then
      local splits = vim.split(node.id, ".", { plain = true, trimempty = true })
      local index = assert(tonumber(splits[#splits]))
      local flow = assert(state.tree:get_node(assert(node:get_parent_id()))).name
      assert(Mark.mark:remove_mark(flow, index))
    else
      return
    end
  end)
end

function M.rename_item(state)
  local node = assert(state.tree:get_node())
  Inputs.input(("rename %s from '%s' to:"):format(node.type, node.name), nil, function(name)
    if not name then
      return
    end
    if node.type == "flow" then
      assert(Mark.mark:rename_flow(node.name, name))
    elseif node.type == "mark" then
      local splits = vim.split(node.id, ".", { plain = true, trimempty = true })
      local index = assert(tonumber(splits[#splits]))
      local flow = assert(state.tree:get_node(assert(node:get_parent_id()))).name
      assert(Mark.mark:rename_mark(flow, index, name))
    else
      return
    end
  end)
end

function M.debug(_)
  vim.notify(vim.inspect(Mark.mark:list_marks()))
end

local cc = require("neo-tree.sources.common.commands")
cc._add_common_commands(M, "^show_help$")
cc._add_common_commands(M, "^cancel$")
cc._add_common_commands(M, "^close_window$")
cc._add_common_commands(M, "^open")
cc._add_common_commands(M, "nodes?$")
cc._add_common_commands(M, "source$")
cc._add_common_commands(M, "preview$")
cc._add_common_commands(M, "^toggle")

return M
