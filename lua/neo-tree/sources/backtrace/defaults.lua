--- @class Traceback.Config
local defaults = {
  dir = vim.fn.stdpath("state") .. "/traceback/",
  branch = true, -- use git branch to save sessions
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
    },
  },
}

return defaults
