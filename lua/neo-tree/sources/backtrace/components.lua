-- This file contains the built-in components. Each componment is a function
-- that takes the following arguments:
--      config: A table containing the configuration provided by the user
--              when declaring this component in their renderer config.
--      node:   A NuiNode object for the currently focused node.
--      state:  The current state of the source providing the items.
--
-- The function should return either a table, or a list of tables, each of which
-- contains the following keys:
--    text:      The text to display for this item.
--    highlight: The highlight group to apply to this text.

-- require("nui.tree").Node
local highlights = require("neo-tree.ui.highlights")
local common = require("neo-tree.sources.common.components")

local M = {
  ---@param node NuiTreeNode
  name = function(_, node, _)
    local text = node.name
    local highlight = highlights.DIM_TEXT
    if node.type == "mark" then
      highlight = highlights.FILE_NAME
    elseif node.type == "flow" then
      highlight = highlights.DIRECTORY_NAME
    end
    return {
      text = text .. " ",
      highlight = highlight,
    }
  end,

  ---@param node NuiTreeNode
  icon = function(config, node, _)
    local text = "unknown node type " .. node.type
    local highlight = highlights.DIM_TEXT
    if node.type == "mark" then
      text = "M"
      highlight = highlights.FILE_ICON
      local success, web_devicons = pcall(require, "nvim-web-devicons")
      if success then
        local devicon, hl = web_devicons.get_icon(node.name, node.ext)
        text = devicon or text
        highlight = hl or highlight
      end
    elseif node.type == "flow" then
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
  end,
}

return vim.tbl_deep_extend("force", common, M)
