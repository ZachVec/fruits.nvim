local renderer = require("neo-tree.ui.renderer")
local Config = require("neo-tree.sources.backtrace.config")
local Manager = require("neo-tree.sources.backtrace.lib.manager")
local Mark = require("neo-tree.sources.backtrace.lib.mark")
local utils = require("neo-tree.sources.backtrace.lib.utils")

local M = {
  -- This is the name our source will be referred to as within Neo-tree
  name = "backtrace",
  -- This is how our source will be displayed in the Source Selector
  display_name = "Backtrace",

  selected_flow = nil,
  manager = nil,
}

---Configures the plugin, should be called before the plugin is used.
---@param config table Configuration table containing any keys that the user
--wants to change from the defaults. May be empty to accept default values.
---@diagnostic disable-next-line: unused-local
function M.setup(config, global_config)
  Config.setup(config)
  local uv = vim.uv or vim.loop

  ---@param err string?
  ---@param content string?
  local function callback(err, content)
    if err then
      vim.notify(string.format("Failed to read: %s", err), vim.log.levels.WARN)
      M.manager = Manager:new()
      return
    end
    assert(content ~= nil, "content is nil")
    M.manager = Manager:loads(content)
  end

  --- Get the manager, create one iff not exist.
  uv.fs_open(M.current(Config.options.dir), "r", 438, function(err1, fd)
    if err1 then
      callback(err1, nil)
      return
    end
    uv.fs_fstat(fd, function(err2, stat)
      if err2 then
        uv.fs_close(fd)
        callback(err2, nil)
        return
      end
      assert(stat ~= nil, "stat is nil")
      vim.loop.fs_read(fd, stat.size, 0, function(err3, data)
        uv.fs_close(fd)
        callback(err3, data)
      end)
    end)
  end)
end

function M.navigate(state)
  -- local mgr = require("neo-tree.sources.backtrace.lib.manager"):new("repo/branch")
  -- mgr:addMark("flow1", Mark:new(0, debug.getinfo(2, "l").currentline, 39))
  -- mgr:addMark("flow1", Mark:new(0, debug.getinfo(2, "l").currentline, 39))
  -- mgr:addMark("flow2", Mark:new(0, debug.getinfo(2, "l").currentline, 39))
  -- mgr:addMark("flow2", Mark:new(0, debug.getinfo(2, "l").currentline, 39))
  renderer.show_nodes(M.manager:toNode(), state)
end

function M.branch()
  local uv = vim.uv or vim.loop
  if uv.fs_stat(".git") then
    local ret = vim.fn.systemlist("git branch --show-current")[1]
    return vim.v.shell_error == 0 and ret or nil
  end
end

function M.current(opts)
  opts = opts or {}
  local name = vim.fn.getcwd():gsub("[\\/:]+", "%%")
  if Config.options.branch and opts.branch ~= false then
    local branch = M.branch()
    if branch and branch ~= "main" and branch ~= "master" then
      name = name .. "%%" .. branch:gsub("[\\/:]+", "%%")
    end
  end
  return Config.options.dir .. name .. ".json"
end

function M.selectFlow()
  vim.ui.select(vim.tbl_keys(M.manager.flows), {
    prompt = "Select Work Flow",
  }, function(choice)
    vim.print("Select " .. choice .. "!")
    if choice then
      vim.print("!Select " .. choice .. "!")
      M.selected_flow = choice
    end
  end)
end

function M.addMark()
  if M.selected_flow == nil then
    vim.notify("Flow not selected, please select one.", vim.log.levels.WARN)
    return false
  end
  local flow = assert(M.selected_flow, string.format("flow %s not found", M.selected_flow))
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(0)
  local cur = vim.api.nvim_win_get_cursor(0)
  local symbol = utils.getContext(bufnr, cur[1], cur[2])
  local mark = Mark:new(path, cur[1], cur[2], bufnr, symbol)
  M.manager:getFlow(flow):addMark(mark)
  return true
end

---@param name string
function M:addFlow(name)
  return self.manager:addFlow(name)
end

---@param name string
function M:delFlow(name)
  if not self.manager:delFlow(name) then
    vim.notify(string.format("Flow %s not found.", name), vim.log.levels.WARN)
  end
end

function M:renameFlow(old, new)
  self.manager:renameFlow(old, new)
end

---@param flow string
---@param index integer
function M:delMark(flow, index)
  -- vim.deep_equal(a, b) + vim.tbl_filter
  assert(self.manager:getFlow(flow), string.format("flow %s not found", flow)):delMark(index)
end

---@param flow string
---@param index integer
---@param name string
function M:modMark(flow, index, name)
  assert(self.manager:getFlow(flow), string.format("flow %s not found", flow))
    :getMark(index)
    :mod(name)
end

return M
