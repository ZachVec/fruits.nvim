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
---@param bufnr integer
---@param symbol string?
---@param fallback string?
function Mark:new(path, lnum, cnum, bufnr, symbol, fallback)
  return setmetatable({
    path = path,
    lnum = lnum,
    cnum = cnum,
    bufnr = bufnr,
    symbol = symbol,
    fallback = fallback,
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
    extra = {
      bufnr = self.bufnr,
      position = { self.lnum - 1, self.cnum },
    },
  }
end

---@class DumpedMark
--- @field symbol string
--- @field path string
--- @field lnum integer
--- @field cnum integer
--- @field fallback string?

---@return DumpedMark
function Mark:dumps()
  return {
    symbol = self.symbol,
    path = self.path,
    lnum = self.lnum,
    cnum = self.cnum,
    fallback = self.fallback,
  }
end

---@param dumped DumpedMark
function Mark.loads(dumped)
  local path = assert(dumped.path, "")
  local lnum = assert(dumped.lnum, "")
  local cnum = assert(dumped.cnum, "")
  local symbol = assert(dumped.symbol, "")
  local fallback = dumped.fallback
  return Mark:new(path, lnum, cnum, vim.fn.bufnr(path), symbol, fallback)
end

return Mark
