--- @alias neotree.sources.mark.Mark {
---   id: string,
---   name: string,
---   type: string,
---   path: string,
---   extra: { bufnr: integer?, position: { [1]: integer, [2]: integer } },
--- }
---
--- @alias neotree.sources.mark.Flow {
---   id: string,
---   name: string,
---   type: string,
---   children: neotree.sources.mark.Mark,
---   extra: { selected: boolean },
--- }

--- @class neotree.sources.mark
--- @field public name string
--- @field public display_name string
--- @field public mark Fruit.mark
--- @field public default_config table
--- @field public to_nodes fun(self: neotree.sources.mark): neotree.sources.mark.Flow[]
--- @field public navigate fun(state: neotree.State)
--- @field public setup fun(config: table, global_config: table)
local M = {
  name = "mark",
  display_name = "󰃀 Marks",
  default_config = require("neo-tree.sources.mark.defaults"),
}

local renderer = require("neo-tree.ui.renderer")
local manager = require("neo-tree.sources.manager")
-- local events = require("neo-tree.events")

function M.navigate(state)
  renderer.show_nodes(M:to_nodes(), state)
end

function M:to_nodes()
  --- @param id string
  --- @param mark Fruit.mark.MarkView
  local function convert_mark(id, mark)
    return vim.tbl_deep_extend("force", mark, {
      id = id,
      type = "mark",
    })
  end

  --- @param id string
  --- @param selected boolean
  --- @param flow Fruit.mark.FlowView
  local function convert_flow(id, selected, flow)
    return vim.tbl_deep_extend("force", flow, {
      id = id,
      type = "flow",
      children = vim
        .iter(flow.children)
        :enumerate()
        :map(
          --- @param index integer
          --- @param mark Fruit.mark.MarkView
          function(index, mark)
            return convert_mark(id .. "." .. index, mark)
          end
        )
        :totable(),
      extra = { selected = selected },
    })
  end

  local working_flow = self.mark:lookup_flow()

  return vim
    .iter(self.mark:list_marks())
    :enumerate()
    --- @param index integer
    --- @param flow Fruit.mark.FlowView
    :map(function(index, flow)
      return convert_flow(tostring(index), flow.name == working_flow, flow)
    end)
    :totable()
end

function M.setup(config, _)
  M.mark = require("fruits.mark")
  M.config = config

  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("NeotreeMark", { clear = true }),
    pattern = "FruitMarkChange",
    callback = function(_)
      local state = manager.get_state(M.name)
      if renderer.window_exists(state) then
        M.navigate(state)
      end
    end,
  })
end

return M
