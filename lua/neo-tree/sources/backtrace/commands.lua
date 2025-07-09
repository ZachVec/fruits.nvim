local Inputs = require("neo-tree.ui.inputs")
local Renderer = require("neo-tree.ui.renderer")
local Preview = require("neo-tree.sources.common.preview")
local Neoutil = require("neo-tree.utils")
local Backtrace = require("neo-tree.sources.backtrace")
local navigate = require("neo-tree.sources.backtrace").navigate
local cc = require("neo-tree.sources.common.commands")

local function open_with_cmd(state, open_cmd, open_file)
  local node = assert(state.tree:get_node())
  if node.type == "flow" then
    local updated = false
    if node:is_expanded() then
      updated = node:collapse()
    else
      updated = node:expand()
    end
    if updated then
      Renderer.redraw(state)
    end
    return
  end

  if node.type == "mark" then
    Preview.hide()
    local path = node.path or node:get_id()
    if type(open_file) == "function" then
      open_file(state, path, open_cmd)
    else
      Neoutil.open_file(state, path, open_cmd)
    end
    local extra = node.extra or {}
    local pos = extra.position or extra.end_position
    if pos ~= nil then
      vim.api.nvim_win_set_cursor(0, { (pos[1] or 0) + 1, pos[2] or 0 })
      vim.api.nvim_win_call(0, function()
        vim.cmd("normal! zvzz") -- expand folds and center cursor
      end)
    end
    return
  end
end

local M = {}

function M.debug(state)
  local node = assert(state.tree:get_node())
  vim.notify(vim.inspect(node))
end

function M.open(state)
  open_with_cmd(state, "e")
end

function M.open_split(state)
  open_with_cmd(state, "split")
end

function M.open_vsplit(state)
  open_with_cmd(state, "vsplit")
end

function M.open_tabnew(state)
  open_with_cmd(state, "tabnew")
end

---@param state neotree.StateWithTree
---@diagnostic disable-next-line: unused-local
function M.refresh(state)
  navigate(state)
end

---@param state neotree.StateWithTree
function M.add_flow(state)
  Inputs.input("Enter flow name", nil, function(name)
    if not name then
      return
    end
    if not Backtrace.manager:create_flow(name) then
      vim.notify(("Flow %s already exists."):format(name), vim.log.levels.WARN)
      return
    end
    navigate(state)
  end)
end

---@param state neotree.StateWithTree
function M.sel_flow(state)
  ---@diagnostic disable-next-line: undefined-field
  local node = assert(state.tree:get_node())
  while node.type ~= "flow" do
    ---@diagnostic disable-next-line: undefined-field
    node = assert(state.tree:get_node(node:get_parent_id()))
  end
  assert(Backtrace.manager:select_flow(node.name), ("flow %s not exist!"):format(node.name))
  navigate(state)
end

---@param state neotree.StateWithTree
function M.delete(state)
  ---@diagnostic disable-next-line: undefined-field
  local node = assert(state.tree:get_node())
  local type = node.type
  local message = ("Confirm delete %s?"):format(type)
  Inputs.confirm(message, function(confirmed)
    if not confirmed then
      return
    end
    if node.type == "flow" then
      assert(Backtrace.manager:remove_flow(node.name), ("flow %s not exist!"):format(node.name))
    elseif node.type == "mark" then
      ---@diagnostic disable-next-line: undefined-field
      local parent = assert(state.tree:get_node(assert(node:get_parent_id())))
      local flow = parent.name
      local ind = vim.split(node.id, ".", { plain = true, trimempty = true })
      assert(#ind == 2)
      Backtrace.manager:remove_mark(flow, assert(tonumber(ind[2])))
    end
    navigate(state)
  end)
end

---@param state neotree.StateWithTree
function M.rename(state)
  ---@diagnostic disable-next-line: undefined-field
  local node = assert(state.tree:get_node())
  local msg = ("rename %s from '%s' to:"):format(node.type, node.name)
  Inputs.input(msg, nil, function(name)
    if not name then
      return
    end
    if node.type == "flow" then
      assert(
        Backtrace.manager:rename_flow(node.name, name),
        ("flow %s not exist!"):format(node.name)
      )
    elseif node.type == "name" then
      ---@diagnostic disable-next-line: undefined-field
      local parent = assert(state.tree:get_node(assert(node:get_parent_id())))
      local flow = parent.name
      local ind = vim.split(node.id, ".", { plain = true, trimempty = true })
      assert(#ind == 2)
      assert(
        Backtrace.manager:rename_mark(flow, assert(tonumber(ind[2])), name),
        ("flow %s not exist!"):format(node.name)
      )
    end
    navigate(state)
  end)
end

cc._add_common_commands(M, "^show_help$")
cc._add_common_commands(M, "^cancel$")
cc._add_common_commands(M, "^close_window$")

cc._add_common_commands(M, "nodes?$")
cc._add_common_commands(M, "source$")
cc._add_common_commands(M, "preview$")
cc._add_common_commands(M, "^toggle")

return M
