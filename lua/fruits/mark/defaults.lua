--- @class Fruit.mark.Opts
--- @field enable boolean?
--- @field branch boolean?
--- @field sign_text string?
--- @field hl_sign { fg: string?, bg: string? }?
--- @field hl_line { fg: string?, bg: string? }?
--- @field directory string?
--- @field formatter fun(bufnr: integer, filename: string, lnum: integer, cnum: integer): string
local M = {
  enable = true,
  branch = true,
  sign_text = "󰂿 ",
  hl_sign = { fg = "#7FFFD4", bg = "NONE" },
  hl_line = { fg = "#7D5C34", bg = "#FFF9E3" },
  directory = vim.fn.stdpath("state") .. "/fruits.nvim/marks/",
  formatter = function(_, filename, _, _)
    local basename = vim.fn.fnamemodify(filename, ":t")
    return ("%s"):format(basename)
  end,
}

return M
