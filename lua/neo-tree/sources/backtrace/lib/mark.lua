---@class BacktraceMark
--- @field private path string string
--- @field private symbol string? the symbol
--- @field private custom string? the string to display if the symbol is not acquired somehow
--- @field private lnum integer used when the mark is not resolved
--- @field private cnum integer used when the mark is not resolved
--- @field private bufnr integer?
--- @field private markid integer?
--- @field private children BacktraceMark?
--- @field public valid boolean
--- @field public new fun(path: string, lnum: integer, cnum: integer, symbol: string?, custom: string?): BacktraceMark Construct a BacktraceMark
--- @field public loads fun(dump: BacktraceDumpedMark): BacktraceMark Construct a BacktraceMark from buffer
--- @field public dumps fun(self: BacktraceMark): BacktraceDumpedMark
--- @field public rename fun(self: BacktraceMark, name: string): nil Modify the fallback field
--- @field public update fun(self: BacktraceMark, ns_id: integer): nil update the lnum and cnum
--- @field public to_node fun(self: BacktraceMark, id: string): BacktraceNode
--- @field public resolve fun(self: BacktraceMark, bufnr: integer, ns_id: integer): BacktraceMark
--- @field public resolved fun(self: BacktraceMark): boolean
--- @field public collects fun(self: BacktraceMark, container: table<string, BacktraceMark[]>)
local M = {}

function M.new(path, lnum, cnum, symbol, custom)
  return setmetatable({
    path = path,
    lnum = lnum,
    cnum = cnum,
    symbol = symbol,
    custom = custom,
    valid = true,
  }, { __index = M })
end

function M.loads(dump)
  return M.new(dump.path, dump.lnum, dump.cnum, dump.symbol, dump.custom)
end

function M:dumps()
  return {
    path = self.path,
    lnum = self.lnum,
    cnum = self.cnum,
    symbol = self.symbol,
    custom = self.custom,
  }
end

function M:rename(name)
  self.custom = name
end

function M:update(ns_id)
  if not self:resolved() then
    return
  end
  local mark = vim.api.nvim_buf_get_extmark_by_id(self.bufnr, ns_id, self.markid, {})
  if mark then
    self.lnum = mark[1] + 1
    self.cnum = mark[2]
  end
end

function M:to_node(id)
  return {
    id = id,
    name = self.custom or self.symbol or "Mark",
    type = "mark",
    path = self.path,
    extra = {
      position = { self.lnum - 1, self.cnum },
    },
  }
end

function M:resolve(bufnr, ns_id)
  self.bufnr = bufnr
  self.markid = vim.api.nvim_buf_set_extmark(bufnr, ns_id, self.lnum - 1, self.cnum, {})
  return self
end

function M:resolved()
  return self.bufnr ~= nil and self.markid ~= nil
end

function M:collects(container)
  local tbl = container[self.path] or {}
  table.insert(tbl, self)
  container[self.path] = tbl
  if self.children ~= nil then
    --- @param mark BacktraceMark
    vim.iter(self.children):each(function(mark)
      mark:collects(container)
    end)
  end
end

return M
