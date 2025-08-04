--- @class Fruit.highlight.Opts
--- @field enable boolean?
--- @field escape boolean?
--- @field hls { name: string, fg: string?, bg: string? }[]
local M = {
  enable = true,
  escape = true,
  hls = {
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

return M
