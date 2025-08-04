--- @class Fruit.mark
--- @field private opts Fruit.mark.Opts
--- @field private flow string | nil
--- @field private hl_group string | nil
--- @field private manager Fruit.mark.Manager
--- @field private branch fun(self: Fruit.mark): string | nil
--- @field private current fun(self: Fruit.mark): string
--- @field private autocmd fun(self: Fruit.mark): nil
--- @field private bfilter fun(self: Fruit.mark): fun(bufnr: integer): boolean
--- @field private fire fun(self: Fruit.mark, event: string)
--- @field public setup fun(opts: Fruit.mark.Opts | nil)
--- @field public lookup_flow fun(self: Fruit.mark): string | nil
--- @field public select_flow fun(self: Fruit.mark, flow: string)
--- @field public create_flow fun(self: Fruit.mark, flow: string): boolean Create a new flow
--- @field public remove_flow fun(self: Fruit.mark, flow: string): boolean Remove an existing flow
--- @field public rename_flow fun(self: Fruit.mark, old_name: string, new_name: string): boolean Rename an existing flow
--- @field public insert_mark fun(self: Fruit.mark): boolean
--- @field public remove_mark fun(self: Fruit.mark, flow: string, index: integer): boolean Remove a mark from a flow by index
--- @field public rename_mark fun(self: Fruit.mark, flow: string, index: integer, name: string): boolean Rename a mark in a flow by index
--- @field public list_flows fun(self: Fruit.mark): string[]
--- @field public list_marks fun(self: Fruit.mark): Fruit.mark.FlowView[]
local M = {}

function M:branch()
  local uv = vim.uv or vim.loop
  if uv.fs_stat(".git") then
    local ret = vim.fn.systemlist("git branch --show-current")[1]
    return vim.v.shell_error == 0 and ret or nil
  end
end

function M:current()
  local name = vim.fn.getcwd():gsub("[\\/:]+", "%%")
  if self.opts.branch ~= false then
    local branch = M:branch()
    if branch and branch ~= "main" and branch ~= "master" then
      name = name .. "%%" .. branch:gsub("[\\/:]+", "%%")
    end
  end
  return self.opts.directory .. name .. ".json"
end

function M:autocmd()
  local augroup = vim.api.nvim_create_augroup("FruitMarkAugroup", { clear = true })
  local bfilter = self:bfilter()

  -- Step1: persist the marks when exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = augroup,
    callback = function()
      if not self.manager:sync_needed() then
        return
      end
      local buffer = vim.json.encode(self.manager:dumps())
      vim.fn.mkdir(self.opts.directory, "p")
      pcall(vim.fn.writefile, { buffer }, self:current())
    end,
  })

  -- Step2: attach marks to bufnr when read a new buffer
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup,
    callback = function(event)
      if bfilter(event.buf) then
        self.manager:attach_path(event.file, event.buf)
      end
    end,
  })

  -- Step3: update marks when buffer is written
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = augroup,
    callback = function(event)
      if bfilter(event.buf) then
        self.manager:update_path(event.match)
      end
    end,
  })

  -- Step4: detach marks when an existing buffer is deleted
  vim.api.nvim_create_autocmd("BufDelete", {
    group = augroup,
    callback = function(event)
      if bfilter(event.buf) then
        self.manager:detach_path(event.file)
      end
    end,
  })
end

function M:bfilter()
  return function()
    return true
  end
end

function M:fire(event)
  vim.api.nvim_exec_autocmds("User", {
    pattern = "FruitMark" .. event,
  })
end

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", require("fruits.mark.defaults"), opts or {})
  local path = M:current()
  local ns_id = vim.api.nvim_create_namespace(path)

  if M.opts.highlight then
    vim.api.nvim_set_hl(0, "FruitMarkDefault", M.opts.highlight)
  end

  if not (vim.uv or vim.loop).fs_stat(path) or vim.fn.isdirectory(path) == 1 then
    M.manager = require("fruits.mark.manager").new(ns_id, true)
  else
    local buffer = vim.json.decode(vim.fn.readfile(path)[1])
    M.manager = require("fruits.mark.manager").loads(ns_id, buffer)
    local flows = M.manager:list_flows()
    if #flows > 0 then
      M.flow = flows[1]
    end
  end

  --- @param bufnr integer
  vim.iter(vim.api.nvim_list_bufs()):filter(M.bfilter(M)):each(function(bufnr)
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if bufname ~= "" and vim.fn.filereadable(bufname) == 1 then
      M.manager:attach_path(bufname, bufnr, "FruitMarkDefault")
    end
  end)

  M:autocmd()
end

function M:lookup_flow()
  return self.flow
end

function M:select_flow(flow)
  self.flow = flow
  self:fire("Change")
end

function M:create_flow(flow)
  local ret = self.manager:create_flow(flow)
  self:fire("Change")
  return ret
end

function M:remove_flow(flow)
  local ret = self.manager:remove_flow(flow)
  self:fire("Change")
  return ret
end

function M:rename_flow(old_name, new_name)
  local ret = self.manager:rename_flow(old_name, new_name)
  self:fire("Change")
  return ret
end

function M:insert_mark()
  if not self.flow then
    vim.notify("Select a flow before inserting mark.")
    return false
  end
  local path = vim.api.nvim_buf_get_name(0)
  local cur = vim.api.nvim_win_get_cursor(0)
  local lnum, cnum = cur[1] - 1, cur[2]
  local name = self.opts.formatter(0, path, lnum, cnum)
  local mark = require("fruits.mark.marks").new(path, name, lnum, cnum)
  mark = mark:attach(self.manager:get_ns_id(), 0, "FruitMarkDefault")
  local ret = self.manager:insert_mark(self.flow, mark)
  self:fire("Change")
  return ret
end

function M:remove_mark(flow, index)
  local ret = self.manager:remove_mark(flow, index)
  self:fire("Change")
  return ret
end

function M:rename_mark(flow, index, name)
  local ret = self.manager:rename_mark(flow, index, name)
  self:fire("Change")
  return ret
end

function M:list_flows()
  return self.manager:list_flows()
end

function M:list_marks()
  return self.manager:list_marks(self.flow)
end

return M
