# highlight

Highlight line in normal mode, Or highlight visual selections!

## Setup

Example using `lazy.nvim`

```lua
{
  "ZachVec/fruits.nvim",
  keys = {
    { "<leader>h1", function () require("fruits").highlight:set("Pink") end, mode = { "n", "v" }, desc = "Pink" },
    { "<leader>hd", function () require("fruits").highlight:reset() end, mode = { "n", "v" }, desc = "delete" },
    -- Or more highlights
    -- { "<leader>h2", function () require("fruits").highlight:set("Latte") end, mode = { "n", "v" }, desc = "Latte" },
  },
  opts = {
    highlight = {
      -- your highlight configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
  }
}
```

## Configuration

```lua
--- @class Fruit.highlight.Opts
--- @field enable boolean?
--- @field escape boolean?
--- @field hls { name: string, fg: string?, bg: string? }[]
{
  enable = true,
  escape = true,
  hls = {
    -- The following highlight groups are created as
    -- FruitHighlightCharcoal, FruitHighlightYellow etc.
    { name = "Charcoal", fg = "#FFC0CB", bg = "#0C0D0E" },
    { name = "Yellow", fg = "#8A2BE2", bg = "#E5C07B" },
    { name = "Menthe", fg = "#1A1A1A", bg = "#7FFFD4" },
    { name = "Purple", fg = "#E5C07B", bg = "#8A2BE2" },
    { name = "Red", fg = "#0C0D0E", bg = "#FF4500" },
    { name = "Green", fg = "#FFC0CB", bg = "#008000" },
    { name = "Blue", fg = "#7FFFD4", bg = "#0000FF" },
    { name = "Pink", fg = "#8A2BE2", bg = "#FFC0CB" },
    { name = "Latte", fg = "#7D5C34", bg = "#FFF9E3" },
    { name = "Brown", fg = "#7FFFD4", bg = "#7D5C34" },
  },
}
```
