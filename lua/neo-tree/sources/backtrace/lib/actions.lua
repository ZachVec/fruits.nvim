local utils = require("neo-tree.sources.backtrace.lib.utils")
local mgr = require("neo-tree.sources.backtrace.lib.manager")
local Mark = require("neo-tree.sources.backtrace.lib.mark")

---@class Action
---@field manager MarksManager
---@field selected_flow string
local Action = {}

function Action:start(opts)
  local path = utils.current(opts)
  local uv = vim.uv or vim.loop

  if not uv.fs_stat(path) or vim.fn.isdirectory(path) == 1 then
    vim.notify(("%s not found!"):format(path), vim.log.levels.WARN)
    self.manager = mgr:new()
    return
  end

  local buffer = vim.json.decode(vim.fn.readfile(path)[1])
  self.manager = mgr:loads(buffer)
end

function Action:select_flow()
  vim.ui.select(vim.tbl_keys(self.manager.flows), {
    prompt = "Select Work Flow",
  }, function(choice)
    if choice then
      Action.selected_flow = choice
    end
  end)
end

function Action:add_mark()
  if self.selected_flow == nil then
    return false
  end
  local flow = assert(self.selected_flow, ("flow %s not found"):format(self.selected_flow))
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(0)
  local cur = vim.api.nvim_win_get_cursor(0)
  local symbol = utils.getContext(bufnr, cur[1], cur[2])
  local mark = Mark:new(path, cur[1], cur[2], bufnr, symbol)
  self.manager:getFlow(flow):addMark(mark)
  self.manager.isDirty = true
  return true
end

---@param name string
function Action:add_flow(name)
  if self.manager:addFlow(name) then
    self.manager.isDirty = true
    return true
  end
  return false
end

---@param name string
function Action:del_flow(name)
  if not self.manager:delFlow(name) then
    vim.notify(("Flow %s not found."):format(name), vim.log.levels.WARN)
  else
    self.manager.isDirty = true
  end
end

function Action:mod_flow(old, new)
  if self.manager:renameFlow(old, new) then
    self.manager.isDirty = true
  end
end

---@param flow string
---@param index integer
function Action:del_mark(flow, index)
  assert(self.manager:getFlow(flow), ("flow %s not found"):format(flow)):delMark(index)
  self.manager.isDirty = true
end

---@param flow string
---@param index integer
---@param name string
function Action:mod_mark(flow, index, name)
  assert(self.manager:getFlow(flow), ("flow %s not found"):format(flow)):getMark(index):mod(name)
  self.manager.isDirty = true
end

function Action:to_nodes()
  return self.manager:toNode()
end

function Action:save(opts)
  if not self.manager.isDirty then
    return true
  end
  local buffer = vim.json.encode(self.manager:dumps())
  return pcall(vim.fn.writefile, { buffer }, utils.current(opts))
end

return Action
