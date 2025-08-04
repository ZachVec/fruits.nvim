--- @class Fruit.Opts
--- @field public highlight Fruit.highlight.Opts?
--- @field public mark Fruit.mark.Opts?

--- @class Fruit
--- @field public highlight Fruit.highlight
--- @field public mark Fruit.mark
--- @field public setup fun(opts: Fruit.Opts | nil)
local M = {}

function M.setup(opts)
  opts = opts or {}
  M.highlight = require("fruits.highlight")
  if opts.highlight and opts.highlight.enable then
    M.highlight.setup(opts.highlight)
  end

  M.mark = require("fruits.mark")
  if opts.mark and opts.mark.enable then
    M.mark.setup(opts.mark)
  end
end

return M
