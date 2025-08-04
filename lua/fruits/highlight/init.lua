--- @class Fruit.highlight
--- @field private ns_id integer
--- @field private opts Fruit.highlight.Opts
--- @field public setup fun(opts: Fruit.highlight.Opts | nil)
--- @field public list fun(): string[] return available names
--- @field public set fun(self: Fruit.highlight, name: string, escape: boolean | nil)
--- @field public reset fun(self: Fruit.highlight, escape: boolean | nil)
local M = {}

function M.setup(opts)
  M.ns_id = vim.api.nvim_create_namespace("FruitHighlight")
  M.mark_ids = {}
  M.opts = vim.tbl_deep_extend("force", require("fruits.highlight.defaults"), opts or {})
  for _, hl in ipairs(M.opts.hls) do
    vim.api.nvim_set_hl(0, "FruitHighlight" .. hl.name, {
      bg = hl.bg,
      fg = hl.fg,
    })
  end
end

function M.list_colors()
  return vim
    .iter(M.opts.hls)
    --- @param hl { name: string, fg: string?, bg: string? }
    :map(function(hl)
      return hl[1]
    end)
    :totable()
end

function M:set(name, escape)
  local actions = require("fruits.highlight.actions")
  local mode = vim.api.nvim_get_mode().mode

  escape = escape or self.opts.escape

  if mode == "n" then
    actions.hl_normal(self.ns_id, "FruitHighlight" .. name)
    return
  end

  if mode == "v" then
    actions.hl_visual(self.ns_id, "FruitHighlight" .. name)
    if escape then
      vim.api.nvim_input("<ESC>")
    end
    return
  end

  if mode == "V" then
    actions.hl_visual_lines(self.ns_id, "FruitHighlight" .. name)
    if escape then
      vim.api.nvim_input("<ESC>")
    end
    return
  end

  if mode == "\22" then
    actions.hl_visual_block(self.ns_id, "FruitHighlight" .. name)
    if escape then
      vim.api.nvim_input("<ESC>")
    end
    return
  end

  vim.notify("Non-visual mode is not supported.", vim.log.levels.WARN)
end

function M:reset(escape)
  local actions = require("fruits.highlight.actions")
  local mode = vim.api.nvim_get_mode().mode
  escape = escape or self.opts.escape
  if mode == "n" then
    actions.reset_hl_normal(self.ns_id)
  elseif mode == "v" then
    actions.reset_hl_visual(self.ns_id)
    if escape then
      vim.api.nvim_input("<ESC>")
    end
  elseif mode == "V" then
    actions.reset_hl_visual_lines(self.ns_id)
    if escape then
      vim.api.nvim_input("<ESC>")
    end
  elseif mode == "\22" then
    actions.reset_hl_visual_block(self.ns_id)
    if escape then
      vim.api.nvim_input("<ESC>")
    end
  end
end

return M
