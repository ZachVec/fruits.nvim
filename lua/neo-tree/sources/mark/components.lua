--- @class neotree.sources.mark.Components
--- @field public name fun(config: neotree.Component.Common.Name, node: NuiTreeNode, state: neotree.State): { text: string, highlight: string }
--- @field public icon fun(config: neotree.Component.Common.Icon, node: NuiTreeNode, state: neotree.State): { text: string, highlight: string }
local M = {}

local highlights = require("neo-tree.ui.highlights")
local common = require("neo-tree.sources.common.components")

function M.name(_, node, _)
  local text = node.name
  local highlight = highlights.DIM_TEXT
  if node.type == "mark" then
    highlight = highlights.FILE_NAME
  elseif node.type == "directory" then
    highlight = highlights.DIRECTORY_NAME
    if node.extra.selected then
      text = text .. " (selected)"
    end
  end
  return { text = text .. " ", highlight = highlight }
end

function M.icon(config, node, _)
  local text = "unknown node type " .. node.type
  local highlight = highlights.DIM_TEXT
  if node.type == "mark" then
    text = "󰂿"
    highlight = highlights.FILE_ICON
    local success, web_devicons = pcall(require, "nvim-web-devicons")
    if success then
      local devicon, hl = web_devicons.get_icon(node.name, node.ext)
      text = devicon or text
      highlight = hl or highlight
    end
  elseif node.type == "directory" then
    if node:is_expanded() then
      text = config.folder_open or "-"
    else
      text = config.folder_closed or "+"
    end
    highlight = highlights.DIRECTORY_ICON
  end
  return {
    text = text .. " ",
    highlight = highlight,
  }
end

return vim.tbl_deep_extend("force", common, M)
