---@class Backtrace.Config
--- @field dir string
--- @field branch boolean
--- @field formatter fun(bufnr: integer, lnum: integer, cnum: integer): string
local M = {
  dir = vim.fn.stdpath("state") .. "/traceback/",

  branch = true, -- use git branch to save sessions

  formatter = function(bufnr, lnum, cnum)
    local data = require("aerial.data")
    local window = require("aerial.window")

    local bufdata = data.get_or_create(bufnr)
    local pos = window.get_symbol_position(bufdata, lnum, cnum, true)
    local symbol = "Unknown Symbol"
    if pos and pos.exact_symbol then
      symbol = pos.exact_symbol["name"]
    end
    return symbol
  end,

  filters = {
    buftypes = { "nofile", "terminal", "prompt" },
    filetyps = { "neo-tree-popup" },
  },

  renderers = {
    flow = {
      { "indent" },
      { "icon" },
      { "name" },
    },
    mark = {
      { "indent" },
      { "icon" },
      { "name" },
    },
  },
  window = {
    mappings = {
      ["c"] = "sel_flow",
      ["x"] = "noop", -- cut to clipboard
      ["y"] = "noop", -- copy to clipboard
      ["A"] = "noop", -- add directory
      ["m"] = "noop", -- move
      ["C"] = "noop", -- close node
      ["S"] = "noop", -- open split
      ["<"] = "prev_source",
      [">"] = "next_source",
      ["?"] = "show_help",
      ["a"] = "add_flow",
      ["d"] = "delete",
      ["r"] = "rename",
      ["<cr>"] = "open",
      ["<esc>"] = "cancel",
      ["q"] = "close_window",
      ["s"] = "open_split",
      ["v"] = "open_vsplit",
      ["t"] = "open_tabnew",
      ["w"] = "noop",
      ["z"] = "close_all_nodes",
      ["p"] = { "toggle_preview", config = { use_float = false } },
      ["D"] = "debug",
    },
  },
}

return M
