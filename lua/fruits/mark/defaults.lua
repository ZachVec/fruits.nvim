--- @class Fruit.mark.Opts
--- @field enable boolean?
--- @field branch boolean?
--- @field highlight { fg: string, bg: string }?
--- @field directory string?
--- @field formatter fun(bufnr: integer, filename: string, lnum: integer, cnum: integer): string
local M = {
  enable = true,
  branch = true,
  highlight = { fg = "#7D5C34", bg = "#FFF9E3" },
  directory = vim.fn.stdpath("state") .. "/fruits.nvim/marks/",
  formatter = function(bufnr, filename, lnum, cnum)
    local basename = vim.fn.fnamemodify(filename, ":t")
    return ("[%d] %s (%d:%d)"):format(bufnr, basename, lnum, cnum)
  end,
}

return M
