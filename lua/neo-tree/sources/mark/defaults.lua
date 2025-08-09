local M = {
  renderers = {
    mark = {
      { "indent" },
      { "icon" },
      { "name" },
    },
  },
  window = {
    mappings = {
      ["a"] = "create_flow",
      ["c"] = "select_flow",
      ["d"] = "delete_item",
      ["r"] = "rename_item",
      ["s"] = "open_split",
      ["p"] = { "toggle_preview", config = { use_float = false } },
      ["x"] = "noop", -- cut to clipboard
      ["m"] = "noop", -- move
      ["y"] = "noop", -- copy to clipboard
      ["A"] = "noop", -- add directory
      ["S"] = "noop", -- open split
      ["<"] = "prev_source",
      [">"] = "next_source",
      ["?"] = "show_help",
      ["<cr>"] = "open",
      ["<esc>"] = "cancel",
      ["D"] = "debug",
      ["R"] = "noop"
    },
  },
}

return M
