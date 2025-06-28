---@class Mark
--- @field path string file path
--- @field lnum integer line number
--- @field cnum integer column number
--- @field bufnr integer? buffer number
--- @field symbol string? symbol name
--- @field fallback string? fallback name
local Mark = {}

---@param path string
---@param lnum integer
---@param cnum integer
---@param bufnr integer?
---@param symbol string?
function Mark:new(path, lnum, cnum, bufnr, symbol)
  return setmetatable({
    path = path,
    lnum = lnum,
    cnum = cnum,
    bufnr = bufnr,
    symbol = symbol,
  }, { __index = Mark })
end

---@param name string
function Mark:mod(name)
  self.fallback = name
end

---@param id string
function Mark:toNode(id)
  return {
    id = id,
    name = self.fallback or self.symbol or "Unknown symbol",
    type = "mark",
    path = self.path,
    lnum = self.lnum,
    cnum = self.cnum,
    bufnr = self.bufnr,
  }
end

return Mark
