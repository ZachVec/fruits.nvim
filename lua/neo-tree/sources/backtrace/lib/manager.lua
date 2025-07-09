---@class BacktraceManager
--- @field private ns_id integer extmark namespace id
--- @field private dirty boolean indicates whether the manager has been modified since loaded
--- @field private flows table<string, BacktraceFlow> name -> flow mapping
--- @field private marks table<string, BacktraceMark[]> path -> mark mapping
--- @field private selected string? selected work flow
--- @field public new fun(ns_id: integer): BacktraceManager
--- @field public loads fun(ns_id: integer, dump: table<string, BacktraceDumpedMark[]>): BacktraceManager
--- @field public dumps fun(self: BacktraceManager): table<string, BacktraceDumpedMark[]>
--- @field public nodes fun(self: BacktraceManager): BacktraceNode[]
--- @field public is_dirty fun(self: BacktraceManager): boolean
--- @field public get_ns_id fun(self: BacktraceManager): integer
--- @field public select_flow fun(self: BacktraceManager, name: string): boolean
--- @field public create_flow fun(self: BacktraceManager, name: string): boolean
--- @field public remove_flow fun(self: BacktraceManager, name: string): boolean
--- @field public rename_flow fun(self: BacktraceManager, old: string, new: string): boolean
--- @field public create_mark fun(self: BacktraceManager, mark: BacktraceMark): boolean
--- @field public remove_mark fun(self: BacktraceManager, name: string, index: integer): boolean
--- @field public rename_mark fun(self: BacktraceManager, name: string, index: integer, new: string): boolean
--- @field public resolve_marks fun(self: BacktraceManager, path: string, bufnr: integer): nil
--- @field public updates_marks fun(self: BacktraceManager, path: string): nil
local M = {}

local FLOW = require("neo-tree.sources.backtrace.lib.flow")

function M.new(ns_id)
  return setmetatable({
    ns_id = ns_id,
    dirty = true,
    flows = {},
    marks = {},
  }, { __index = M })
end

function M.loads(ns_id, dump)
  local manager = M.new(ns_id)
  manager.dirty = false
  for name, marks in pairs(dump) do
    local flows = FLOW.loads(marks)
    manager.flows[name] = flows
    flows:collects(manager.marks)
  end
  if vim.tbl_count(manager.flows) == 1 then
    manager.selected = vim.tbl_keys(manager.flows)[1]
  end
  for path, marks in pairs(manager.marks) do
    local bufnr = vim.fn.bufnr(path)
    if bufnr ~= -1 then
      --- @param mark BacktraceMark
      vim.iter(marks):each(function(mark)
        mark:resolve(bufnr, ns_id)
      end)
    end
  end
  return manager
end

function M:dumps()
  local dumpedTable = {}
  for name, flow in pairs(self.flows) do
    dumpedTable[name] = flow:dumps()
  end
  return dumpedTable
end

function M:nodes()
  return vim
    .iter(vim.spairs(self.flows))
    :enumerate()
    :map(
      --- @param index integer
      --- @param name string
      --- @param flow BacktraceFlow
      function(index, name, flow)
        return flow:to_nodes(tostring(index), name, name == self.selected)
      end
    )
    :totable()
end

function M:is_dirty()
  return self.dirty
end

function M:get_ns_id()
  return self.ns_id
end

function M:select_flow(name)
  if self.flows[name] ~= nil then
    self.selected = name
    return true
  end
  return false
end

function M:create_flow(name)
  local flow = self.flows[name]
  if flow ~= nil then
    return false
  end
  self.flows[name] = FLOW:new()
  self.dirty = true
  return true
end

function M:remove_flow(name)
  local flow = self.flows[name]
  if flow == nil then
    return false
  end
  self.flows[name] = nil
  self.dirty = true
  return true
end

function M:rename_flow(old, new)
  if new == old or self.flows[new] ~= nil or self.flows[old] == nil then
    return false
  end
  self.flows[new] = self.flows[old]
  self.flows[old] = nil
  self.dirty = true
  return true
end

function M:create_mark(mark)
  local flow = self.flows[self.selected]
  if flow == nil then
    return false
  end
  flow:add_mark(mark):collects(self.marks)
  self.dirty = true
  return true
end

function M:remove_mark(name, index)
  local flow = self.flows[name]
  if flow == nil then
    return false
  end
  self.dirty = true

  --- @type table<string, BacktraceMark[]>
  local container = {}

  local mark = flow:del_mark(index)
  if mark ~= nil then
    mark:collects(container)
  end
  for _, marks in pairs(container) do
    --- @param m BacktraceMark
    vim.iter(marks):each(function(m)
      m.valid = false
    end)
  end
  --- async remove mark or remove marks when dump
  return true
end

function M:rename_mark(name, index, new)
  local flow = self.flows[name]
  if flow == nil then
    return false
  end
  local mark = flow:get_mark(index)
  if mark == nil then
    return false
  end
  mark:rename(new)
  self.dirty = true
  return true
end

function M:resolve_marks(path, bufnr)
  vim
    .iter(self.marks[path] or {})
    --- @param mark BacktraceMark
    :filter(function(mark)
      return mark.valid
    end)
    --- @param mark BacktraceMark
    :each(function(mark)
      mark:resolve(bufnr, self.ns_id)
    end)
end

function M:updates_marks(path)
  vim
    .iter(self.marks[path] or {})
    --- @param mark BacktraceMark
    :filter(function(mark)
      return mark.valid
    end)
    --- @param mark BacktraceMark
    :each(function(mark)
      mark:update(self.ns_id)
    end)
  self.dirty = true
end

return M
