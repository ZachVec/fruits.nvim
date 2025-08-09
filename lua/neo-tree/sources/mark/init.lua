--- @class neotree.sources.mark
--- @field public name string
--- @field public display_name string
--- @field public mark Fruit.mark
--- @field public flow NuiTree.Node | nil
--- @field public config table
--- @field public default_config table
--- @field public setup fun(config: table, global_config: table)
--- @field public navigate fun(state: neotree.State)
--- @field public to_nodes fun(self: neotree.sources.mark): neotree.sources.mark.Flow[]
--- @field public create_mark fun(self: neotree.sources.mark)
local M = {
  name = "mark",
  display_name = "󰃀 Marks",
  default_config = require("neo-tree.sources.mark.defaults"),
}

local renderer = require("neo-tree.ui.renderer")
local manager = require("neo-tree.sources.manager")
local events = require("neo-tree.events")

function M.setup(config, _)
  M.mark = require("fruits.mark")
  local flows = M.mark:list_flows()
  table.sort(flows)
  M.config = config

  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("NeotreeMark", { clear = true }),
    pattern = { "FruitMarkAttach", "FruitMarkDetach" },
    callback = function(_)
      local state = manager.get_state(M.name)
      if renderer.window_exists(state) then
        M.navigate(state)
      end
    end,
  })

  manager.subscribe(M.name, {
    event = events.FILE_OPEN_REQUESTED,
    --- @type fun(arg: { state: neotree.StateWithTree, path: string, open_cmd: string, bufnr: integer })
    handler = function(arg)
      local state = arg.state
      local success, node = pcall(state.tree.get_node, state.tree)
      if not (success and node) then
        vim.notify("Could not get node.", vim.log.levels.WARN)
        return
      end
      if node.type == "mark" then
        --- @type { bufnr: integer, ns_id: integer, markid: integer } | nil
        local mark = node.extra.mark
        if mark ~= nil then
          node.extra.position =
            vim.api.nvim_buf_get_extmark_by_id(mark.bufnr, mark.ns_id, mark.markid, {
              details = false,
            })
        end
      end
    end,
  })

  events.define_event("after_modify_tree", {})
  manager.subscribe(M.name, {
    event = "after_modify_tree",
    handler = function(state)
      if renderer.window_exists(state) then
        M.navigate(state)
      end
    end,
  })

  events.define_event("after_select_flow", {})
  manager.subscribe(M.name, {
    event = "after_select_flow",
    --- @type fun(arg: { state: neotree.StateWithTree, prev: NuiTree.Node | nil, curr: NuiTree.Node })
    handler = function(arg)
      local state, prev, curr = arg.state, arg.prev, arg.curr
      if prev ~= nil then
        assert(state.tree:get_node(prev.id)).extra.selected = false
      end
      curr.extra.selected = true
      if renderer.window_exists(state) then
        renderer.redraw(state)
      end
    end,
  })
end

function M.navigate(state)
  renderer.show_nodes(M:to_nodes(), state)
end

function M:to_nodes()
  --- @type fun(id:string, mark: Fruit.mark.MarkView): neotree.sources.mark.Mark
  local function convert_mark(id, mark)
    --- @cast mark neotree.sources.mark.Mark
    mark.id = id
    mark.type = "mark"
    return mark
  end

  --- @type fun(id: string, flow: Fruit.mark.FlowView): neotree.sources.mark.Flow
  local function convert_flow(id, flow)
    local children = vim
      .iter(ipairs(flow.children))
      :map(
        --- @param index integer
        --- @param mark Fruit.mark.MarkView
        --- @return neotree.sources.mark.Mark
        function(index, mark)
          return convert_mark(id .. "." .. index, mark)
        end
      )
      :totable()
    --- @cast flow neotree.sources.mark.Flow
    flow.id = id
    flow.type = "directory"
    flow.children = children
    flow.extra = { selected = self.flow and self.flow.name == flow.name or false }
    return flow
  end

  local marks = self.mark:list_marks()
  table.sort(marks, function(a, b)
    return a.name < b.name
  end)

  return vim
    .iter(ipairs(marks))
    --- @param index integer
    --- @param flow Fruit.mark.FlowView
    :map(function(index, flow)
      return convert_flow(tostring(index), flow)
    end)
    :totable()
end

function M:create_mark()
  if not self.flow then
    vim.notify("Select a flow before creating marks.", vim.log.levels.WARN)
    return
  end
  self.mark:insert_mark(self.flow.name)
  events.fire_event("after_modify_tree", manager.get_state(M.name))
end

return M
