---@class BacktraceModule
--- @field private is_valid_buf fun(bufnr: integer): boolean
--- @field name string
--- @field display_name string
--- @field default_config Backtrace.Config
--- @field navigate fun(state: neotree.State, path: string?)
--- @field config Backtrace.Config
--- @field manager BacktraceManager
--- @field setup fun(config: Backtrace.Config, global_config: table)
--- @field create_mark fun(): nil
local M = {}

function M.is_valid_buf(bufnr)
  local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })

  if vim.tbl_contains(M.config.filters.buftypes, buftype) then
    return false
  end

  local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
  if vim.tbl_contains(M.config.filters.filetyps, filetype) then
    return false
  end
  return true
end

local renderer = require("neo-tree.ui.renderer")
local manager = require("neo-tree.sources.manager")
local MarksManager = require("neo-tree.sources.backtrace.lib.manager")
local Mark = require("neo-tree.sources.backtrace.lib.mark")
local utils = require("neo-tree.sources.backtrace.lib.utils")

M.name = "backtrace"

M.display_name = "󰃀 Trace"

M.default_config = require("neo-tree.sources.backtrace.defaults")

---@diagnostic disable-next-line: unused-local
function M.navigate(state, path)
  renderer.show_nodes(M.manager:nodes(), state)
end

---@diagnostic disable-next-line: unused-local
function M.setup(config, global_config)
  M.config = config

  --- TODO: fix broken trace if rename/delete

  -- manager.subscribe(M.name, {
  --   event = events.FILE_OPENED,
  --   handler = function(args)
  --     vim.notify(("handler triggered: %s"):format(vim.inspect(args)))
  --     manager.refresh(M.name)
  --   end,
  -- })

  -- NOTE: Load manager from disk
  local ns_id = vim.api.nvim_create_namespace(utils.current(config))
  local path = utils.current(config)
  local uv = vim.uv or vim.loop
  if not uv.fs_stat(path) or vim.fn.isdirectory(path) == 1 then
    M.manager = MarksManager.new(ns_id)
  else
    local buffer = vim.json.decode(vim.fn.readfile(path)[1])
    M.manager = MarksManager.loads(ns_id, buffer)
  end

  -- NOTE: persist the marks when exit
  local augroup = vim.api.nvim_create_augroup("backtrace", { clear = true })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = augroup,
    callback = function()
      if M.manager:is_dirty() then
        local buffer = vim.json.encode(M.manager:dumps())
        if not pcall(vim.fn.writefile, { buffer }, utils.current(config)) then
          vim.notify("Write failed, please check if filesystem is full!", vim.log.levels.WARN)
        end
      end
    end,
  })

  -- NOTE: resove the marks when BufReadPost
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup,
    callback = function(event)
      if M.is_valid_buf(event.buf) then
        M.manager:resolve_marks(event.file, event.buf)
      end
    end,
  })

  -- NOTE: update the marks when BufUnload
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = augroup,
    callback = function(event)
      if M.is_valid_buf(event.buf) then
        M.manager:updates_marks(event.match)
        local state = manager.get_state(M.name)
        if renderer.window_exists(state) then
          M.navigate(state)
        end
      end
    end,
  })
end

function M.create_mark()
  local bufnr = vim.api.nvim_get_current_buf()

  if not M.is_valid_buf(bufnr) then
    return
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local name = M.config.formatter(bufnr, cursor[1], cursor[2])
  local mark = Mark.new(path, cursor[1], cursor[2], name):resolve(bufnr, M.manager:get_ns_id())
  if not M.manager:create_mark(mark) then
    vim.notify("Select flow before adding marks.", vim.log.levels.WARN)
    return
  end
  local state = manager.get_state(M.name)
  if renderer.window_exists(state) then
    M.navigate(state)
  end
end

return M
