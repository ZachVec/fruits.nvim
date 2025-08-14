--- @class Fruit.mark
--- @field private opts Fruit.mark.Opts
--- @field private path string
--- @field private ns_id integer
--- @field private dirty boolean
--- @field private manager Fruit.mark.Manager
--- @field private save fun(self: Fruit.mark, path: string)
--- @field private load fun(self: Fruit.mark, path: string)
--- @field private attach fun(self: Fruit.mark, opts: { bufnrs: integer | integer[] | nil, paths: string | string[] })
--- @field private detach fun(self: Fruit.mark, opts: { bufnrs: integer | integer[] | nil, paths: string | string[] })
--- @field private current fun(self: Fruit.mark): string get cache filename of current project
--- @field private autocmd fun(self: Fruit.mark): nil register all auto commands
--- @field private bfilter fun(self: Fruit.mark): fun(bufnr: integer): boolean buffer filter for buffers to attach
--- @field public setup fun(opts: Fruit.mark.Opts | nil)
--- @field public list_flows fun(self: Fruit.mark): string[]
--- @field public list_marks fun(self: Fruit.mark): Fruit.mark.FlowView[]
--- @field public create_flow fun(self: Fruit.mark, flow: string): boolean Create a new flow
--- @field public remove_flow fun(self: Fruit.mark, flow: string): boolean Remove an existing flow
--- @field public rename_flow fun(self: Fruit.mark, old_name: string, new_name: string): boolean Rename an existing flow
--- @field public insert_mark fun(self: Fruit.mark, flow: string): boolean
--- @field public remove_mark fun(self: Fruit.mark, flow: string, index: integer): boolean Remove a mark from a flow by index
--- @field public rename_mark fun(self: Fruit.mark, flow: string, index: integer, name: string): boolean Rename a mark in a flow by index
local M = {}

function M:save(path)
  if not self.dirty then
    return
  end
  local buffer = vim.json.encode(self.manager:dump())
  vim.fn.mkdir(self.opts.directory, "p")
  pcall(vim.fn.writefile, { buffer }, path)
  self.dirty = false
end

function M:load(path)
  if not (vim.uv or vim.loop).fs_stat(path) or vim.fn.isdirectory(path) == 1 then
    self.manager = require("fruits.mark.manager").new()
    self.dirty = false
  else
    local buffer = vim.json.decode(vim.fn.readfile(path)[1])
    self.manager = require("fruits.mark.manager").load(buffer)
    self.dirty = false
  end
end

function M:attach(opts)
  local bufnrs = opts.bufnrs or {}
  if type(bufnrs) == "integer" then
    bufnrs = { bufnrs }
  end

  local paths = opts.paths or {}
  if type(paths) == "string" then
    paths = { paths }
  end
  --- @param path string
  vim.iter(paths):each(function(path)
    table.insert(bufnrs, vim.fn.bufadd(path))
  end)

  --- @param bufnr integer
  vim.iter(bufnrs):each(function(bufnr)
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if bufname ~= "" and vim.fn.filereadable(bufname) then
      if pcall(vim.fn.bufload, bufnr) then
        self.manager:each_mark(bufname, function(mark)
          mark:attach(self.ns_id, bufnr, self.opts.sign_text)
        end)
      else
        local message = ("Swapfile for %s found, skip loading."):format(bufname)
        vim.notify(message, vim.log.levels.WARN)
      end
    end
  end)
end

function M:detach(opts)
  local paths = opts.paths or {}
  if type(paths) == "string" then
    paths = { paths }
  end
  local bufnrs = opts.bufnrs or {}
  if type(bufnrs) == "integer" then
    bufnrs = { bufnrs }
  end
  --- @param bufnr integer
  vim.iter(bufnrs):each(function(bufnr)
    table.insert(paths, vim.api.nvim_buf_get_name(bufnr))
  end)

  --- @param path string
  vim.iter(paths):each(function(path)
    -- local bufname = vim.api.nvim_buf_get_name(bufnr)
    self.manager:each_mark(path, function(mark)
      self.dirty = mark:detach(self.ns_id) or self.dirty
    end)
  end)
end

function M:current()
  local function current_branch()
    local uv = vim.uv or vim.loop
    if uv.fs_stat(".git") then
      local ret = vim.fn.systemlist("git branch --show-current")[1]
      return vim.v.shell_error == 0 and ret or nil
    end
  end
  local name = vim.fn.getcwd():gsub("[\\/:]+", "%%")
  if self.opts.branch ~= false then
    local branch = current_branch()
    if branch and branch ~= "main" and branch ~= "master" then
      name = name .. "%%" .. branch:gsub("[\\/:]+", "%%")
    end
  end
  return self.opts.directory .. name .. ".json"
end

function M:bfilter()
  return function(bufnr)
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
    return buftype ~= "nofile"
  end
end

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", require("fruits.mark.defaults"), opts or {})
  if M.opts.sign_text and M.opts.hl_sign then
    vim.api.nvim_set_hl(0, "FruitMarkSign", M.opts.hl_sign)
  end
  if M.opts.hl_line then
    vim.api.nvim_set_hl(0, "FruitMarkLine", M.opts.hl_line)
  end

  M.path = M:current()
  M.ns_id = vim.api.nvim_create_namespace(M.path)
  M:load(M.path)
  M:attach({ bufnrs = vim.iter(vim.api.nvim_list_bufs()):filter(M.bfilter(M)):totable() })
  M:autocmd()

  --- @param fn fun(self: Fruit.mark, ...): boolean
  local function wrapper(fn)
    --- @param self Fruit.mark
    local function decorated(self, ...)
      if not fn(self, ...) then
        return false
      end
      ---@diagnostic disable-next-line: invisible
      self.dirty = true
      return true
    end
    return decorated
  end

  M.create_flow = wrapper(M.create_flow)
  M.remove_flow = wrapper(M.remove_flow)
  M.rename_flow = wrapper(M.rename_flow)
  M.insert_mark = wrapper(M.insert_mark)
  M.remove_mark = wrapper(M.remove_mark)
  M.rename_mark = wrapper(M.rename_mark)
end

function M:autocmd()
  local bfilter = self:bfilter()

  local augroup = vim.api.nvim_create_augroup("FruitMarkAugroup", { clear = true })

  -- Step1: persist the marks when exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = augroup,
    callback = function()
      self:detach({ bufnrs = vim.iter(vim.api.nvim_list_bufs()):filter(bfilter):totable() })
      self:save(self.path)
    end,
  })

  -- Step2: attach marks to bufnr when read a new buffer
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup,
    callback = function(event)
      if bfilter(event.buf) then
        self:attach({ paths = event.match })
        vim.api.nvim_exec_autocmds("User", { pattern = "FruitMarkAttach" })
      end
    end,
  })

  -- Step3: detach marks when an existing buffer is deleted
  vim.api.nvim_create_autocmd("BufDelete", {
    group = augroup,
    callback = function(event)
      if bfilter(event.buf) then
        self:detach({ paths = event.match })
        vim.api.nvim_exec_autocmds("User", { pattern = "FruitMarkDetach" })
      end
    end,
  })
end

function M:create_flow(flow)
  return self.manager:create_flow(flow)
end

function M:remove_flow(flow)
  local marks = self.manager:remove_flow(flow)
  for _, mark in ipairs(marks or {}) do
    mark:detach(self.ns_id)
  end
  return marks ~= nil
end

function M:rename_flow(old_name, new_name)
  return self.manager:rename_flow(old_name, new_name)
end

function M:insert_mark(flow)
  local path = vim.api.nvim_buf_get_name(0)
  local cur = vim.api.nvim_win_get_cursor(0)
  local lnum, cnum = cur[1] - 1, cur[2]
  local name = self.opts.formatter(0, path, lnum, cnum)
  local mark = require("fruits.mark.marks").new(path, name, lnum, cnum)
  mark:attach(self.ns_id, 0, self.opts.sign_text)
  return self.manager:insert_mark(flow, mark)
end

function M:remove_mark(flow, index)
  local mark = self.manager:remove_mark(flow, index)
  if mark then
    mark:detach(self.ns_id)
  end
  return mark ~= nil
end

function M:rename_mark(flow, index, name)
  return self.manager:rename_mark(flow, index, name)
end

function M:list_flows()
  return vim.tbl_keys(self.manager.flow_marks)
end

function M:list_marks()
  return self.manager:list(self.ns_id)
end

return M
