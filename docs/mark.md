# Mark

Create marks and track it via neo-tree.

## Setup

```lua
{
  "ZachVec/fruits.nvim",
  dependencies = {
    "nvim-neo-tree/neo-tree.nvim",
  },
  keys = {
    { "<leader>am", function () require("neo-tree.sources.mark"):create_mark() end, desc = "Create Mark at cursor" },
    { "<leader>em", function () require("neo-tree.command").execute({ source = "mark", toggle = true }) end, desc = "Mark Explorer" }
  },
  opts = {
    mark = {
      -- your highlight configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
  }
}
```

## Configuration

```lua
--- @class Fruit.mark.Opts
--- @field enable boolean?
--- @field branch boolean?
--- @field sign_text string?
--- @field hl_sign { fg: string?, bg: string? }?
--- @field hl_line { fg: string?, bg: string? }?
--- @field directory string?
--- @field formatter fun(bufnr: integer, filename: string, lnum: integer, cnum: integer): string
{
  enable = true,    -- plugin enabled
  branch = true,    -- each branch has its own marks
  sign_text = "󰂿 ", -- sign_text one mark line
  hl_sign = { fg = "#7FFFD4", bg = "NONE" },  -- hl_group for sign_text
  hl_line = { fg = "#7D5C34", bg = "#FFF9E3" },  -- hl_group for hl_line
  directory = vim.fn.stdpath("state") .. "/fruits.nvim/marks/",  -- directory to store marks
  formatter = function(_, filename, _, _)   -- how the name of mark is generated
    local basename = vim.fn.fnamemodify(filename, ":t")
    return ("%s"):format(basename)
  end,
}
```

And set the key map to highlight
