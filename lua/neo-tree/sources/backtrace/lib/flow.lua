---@class BacktraceFlow
--- @field private marks BacktraceMark[]
--- @field public new fun(): BacktraceFlow
--- @field public loads fun(dump: BacktraceDumpedMark[]): BacktraceFlow
--- @field public dumps fun(self: BacktraceFlow): BacktraceDumpedMark[]
--- @field public add_mark fun(self: BacktraceFlow, mark: BacktraceMark): BacktraceMark
--- @field public del_mark fun(self: BacktraceFlow, index: integer): BacktraceMark?
--- @field public get_mark fun(self: BacktraceFlow, index: integer): BacktraceMark?
--- @field public swp_mark fun(self: BacktraceFlow, i: integer): boolean swap mark downwards
--- @field public to_nodes fun(self: BacktraceFlow, id: string, name: string, selected: boolean): BacktraceNode
--- @field public collects fun(self: BacktraceFlow, container: table<string, BacktraceMark[]>)
local M = {}

local MARK = require("neo-tree.sources.backtrace.lib.mark")

function M.new()
  return setmetatable({ marks = {} }, { __index = M })
end

function M.loads(dump)
  local ret = M.new()
  ret.marks = vim.iter(dump):map(MARK.loads):totable()
  return ret
end

function M:dumps()
  return vim.iter(self.marks):map(MARK.dumps):totable()
end

function M:add_mark(mark)
  table.insert(self.marks, #self.marks + 1, mark)
  return mark
end

function M:del_mark(index)
  return table.remove(self.marks, index)
end

function M:get_mark(index)
  return self.marks[index]
end

function M:swp_mark(i)
  if i >= #self.marks then
    return false
  end
  self.marks[i], self.marks[i + 1] = self.marks[i + 1], self.marks[i]
  return true
end

function M:to_nodes(id, name, selected)
  local children = vim
    .iter(ipairs(self.marks))
    --- @param index integer
    --- @param mark BacktraceMark
    :map(function(index, mark)
      return mark:to_node(id .. "." .. tostring(index))
    end)
    :totable()
  return {
    id = id,
    name = name,
    type = "flow",
    children = children,
    extra = {
      selected = selected,
    },
  }
end

function M:collects(container)
  --- @param mark BacktraceMark
  vim.iter(self.marks):each(function(mark)
    mark:collects(container)
  end)
end

return M
