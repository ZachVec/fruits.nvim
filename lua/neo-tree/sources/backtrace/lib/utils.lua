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
  if opts.branch ~= false then
    local branch = M.branch()
    if branch and branch ~= "main" and branch ~= "master" then
      name = name .. "%%" .. branch:gsub("[\\/:]+", "%%")
    end
  end
  return opts.dir .. name .. ".json"
end

return M
