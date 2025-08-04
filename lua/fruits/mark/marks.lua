--- @alias Fruit.mark.MarkView { name: string, path: string, extra: { bufnr: integer?, position: { [1]: integer, [2]: integer }? } }
--- @alias Fruit.mark.SerializedMark { path: string, name: string, lnum: integer, cnum: integer }

--- @class Fruit.mark.Mark
--- @field protected path string
--- @field protected name string
--- @field protected lnum integer
--- @field protected cnum integer
--- @field protected extra { bufnr: integer?, markid: integer? }
--- @field public new fun(path: string, name: string, lnum: integer, cnum: integer): Fruit.mark.Mark
--- @field public loads fun(mark: Fruit.mark.SerializedMark): Fruit.mark.Mark
--- @field public dumps fun(self: Fruit.mark.Mark): Fruit.mark.SerializedMark
--- @field public rename fun(self: Fruit.mark.Mark, name: string): nil
--- @field public update fun(self: Fruit.mark.Mark, nsid: integer): boolean get called after the buffer is modified and saved
--- @field public attach fun(self: Fruit.mark.Mark, nsid: integer, bufnr: integer, hl_group: string | nil): Fruit.mark.Mark return reference to self
--- @field public detach fun(self: Fruit.mark.Mark, nsid: integer): Fruit.mark.Mark
--- @field public gather fun(self: Fruit.mark.Mark, result: table<string, Fruit.mark.Mark[]>)
--- @field public remove fun(self: Fruit.mark.Mark, holder: table<string, Fruit.mark.Mark[]>)
--- @field public lookup fun(self: Fruit.mark.Mark): Fruit.mark.MarkView
local M = {}

function M.new(path, name, lnum, cnum)
  return setmetatable({
    path = path,
    name = name,
    lnum = lnum,
    cnum = cnum,
    extra = {},
  }, { __index = M })
end

function M.loads(mark)
  return M.new(mark.path, mark.name, mark.lnum, mark.cnum)
end

function M:dumps()
  return { path = self.path, name = self.name, lnum = self.lnum, cnum = self.cnum }
end

function M:rename(name)
  self.name = name
end

function M:update(nsid)
  local bufnr, markid = self.extra.bufnr, self.extra.markid
  if bufnr == nil or markid == nil then
    return false
  end
  local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, nsid, markid, {})
  self.lnum, self.cnum = mark[1], mark[2]
  return true
end

function M:attach(nsid, bufnr, hl_group)
  bufnr = bufnr > 0 and bufnr or vim.api.nvim_get_current_buf()

  local lines = vim.api.nvim_buf_get_lines(bufnr, self.lnum, self.lnum + 1, false)
  local length = #lines > 0 and #lines[1] or 0
  self.extra.bufnr = bufnr
  self.extra.markid = vim.api.nvim_buf_set_extmark(bufnr, nsid, self.lnum, 0, {
    hl_group = hl_group,
    end_row = self.lnum,
    end_col = length,
  })
  return self
end

function M:detach(nsid)
  local bufnr, markid = assert(self.extra.bufnr), assert(self.extra.markid)
  self.extra.bufnr, self.extra.markid = nil, nil
  -- stylua: ignore
  assert(vim.api.nvim_buf_del_extmark(bufnr, nsid, markid), ("Failed to delete mark: %s"):format(vim.inspect(self)))
  return self
end

function M:gather(result)
  local path = result[self.path] or {}
  table.insert(path, self)
  result[self.path] = path
end

function M:remove(sources)
  local marks = assert(sources[self.path])
  local index = nil
  for i, mark in ipairs(marks) do
    if mark == self then
      index = i
    end
  end
  assert(index)
  table.remove(marks, index)
  sources[self.path] = marks
end

function M:lookup()
  return {
    name = self.name,
    path = self.path,
    extra = {
      bufnr = self.extra.bufnr,
      position = { self.lnum, self.cnum },
    },
  }
end

return M
