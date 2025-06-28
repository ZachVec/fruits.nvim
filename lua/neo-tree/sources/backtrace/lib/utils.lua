local data = require("aerial.data")
local window = require("aerial.window")

local M = {}

--- Get symbol at given position
---@param bufnr integer buffer number
---@param lnum integer line number
---@param cnum integer column number
function M.getContext(bufnr, lnum, cnum)
  local bufdata = data.get_or_create(bufnr)
  local pos = window.get_symbol_position(bufdata, lnum, cnum, true)
  if pos and pos.exact_symbol then
    return pos.exact_symbol["name"]
  end
end

return M
