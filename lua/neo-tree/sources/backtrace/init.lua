local renderer = require("neo-tree.ui.renderer")
local manager = require("neo-tree.sources.manager")
local actions = require("neo-tree.sources.backtrace.lib.actions")

local M = {
  -- This is the name our source will be referred to as within Neo-tree
  name = "backtrace",
  -- This is how our source will be displayed in the Source Selector
  display_name = "Backtrace",

  default_config = require("neo-tree.sources.backtrace.defaults"),

  start = function(opts)
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = vim.api.nvim_create_augroup("backtrace", { clear = true }),
      callback = function()
        if not actions:save(opts) then
          vim.notify("Write failed, please check if filesystem is full!", vim.log.levels.WARN)
        end
      end,
    })
  end,

  navigate = function(state)
    renderer.show_nodes(actions:to_nodes(), state)
  end,
}

function M.add_mark()
  if not actions:add_mark() then
    vim.notify("Flow not selected, please select one.", vim.log.levels.WARN)
  end
  M.navigate(manager.get_state(M.name))
end

function M.sel_flow()
  actions:select_flow()
  M.navigate(manager.get_state(M.name))
end

---Configures the plugin, should be called before the plugin is used.
---@param config table Configuration table containing any keys that the user
-- wants to change from the defaults. May be empty to accept default values.
---@diagnostic disable-next-line: unused-local
function M.setup(config, global_config)
  M.start(config)
  actions:start(config)
end

return M
