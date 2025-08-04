--- @alias Fruit.mark.FlowView { name: string, children: Fruit.mark.MarkView[], extra: { selected: boolean } }

--- @class Fruit.mark.Manager
--- @field protected dirty boolean  need to sync data to disk
--- @field protected ns_id integer
--- @field protected flow_marks table<string, Fruit.mark.Mark[]> flow -> marks mapping
--- @field protected path_marks table<string, Fruit.mark.Mark[]> path -> marks mapping
--- @field public new fun(ns_id: integer, dirty: boolean | nil): Fruit.mark.Manager
--- @field public get_ns_id fun(self: Fruit.mark.Manager): integer
--- @field public loads fun(ns_id: integer, marks: table<string, Fruit.mark.SerializedMark[]>): Fruit.mark.Manager
--- @field public dumps fun(self: Fruit.mark.Manager): table<string, Fruit.mark.SerializedMark[]>
--- @field public sync_needed fun(self: Fruit.mark.Manager): boolean
--- @field public create_flow fun(self: Fruit.mark.Manager, flow: string): boolean Create a new flow
--- @field public remove_flow fun(self: Fruit.mark.Manager, flow: string): boolean Remove an existing flow
--- @field public rename_flow fun(self: Fruit.mark.Manager, old_name: string, new_name: string): boolean Rename an existing flow
--- @field public insert_mark fun(self: Fruit.mark.Manager, flow: string, mark: Fruit.mark.Mark): boolean Insert a mark into a flow
--- @field public remove_mark fun(self: Fruit.mark.Manager, flow: string, index: integer): boolean Remove a mark from a flow by index
--- @field public rename_mark fun(self: Fruit.mark.Manager, flow: string, index: integer, name: string): boolean Rename a mark in a flow by index
--- @field public attach_path fun(self: Fruit.mark.Manager, path: string, bufnr: integer, hl_group: string | nil): nil Attach all marks for a path to a buffer
--- @field public detach_path fun(self: Fruit.mark.Manager, path: string): nil Detach all marks for a path from their buffers
--- @field public update_path fun(self: Fruit.mark.Manager, path: string): nil Update all marks for a path
--- @field public list_flows fun(self: Fruit.mark.Manager): string[]
--- @field public list_marks fun(self: Fruit.mark.Manager, selected: string | nil): Fruit.mark.FlowView[]
local M = {}

function M.new(ns_id, dirty)
  return setmetatable({
    ns_id = ns_id,
    dirty = dirty or true,
    flow_marks = {},
    path_marks = {},
  }, { __index = M })
end

function M:get_ns_id()
  return self.ns_id
end

function M.loads(ns_id, marks)
  local Mark = require("fruits.mark.marks")
  local manager = M.new(ns_id, false)
  for flow, submarks in pairs(marks) do
    vim.iter(submarks):map(Mark.loads):each(function(mark)
      M.insert_mark(manager, flow, mark)
    end)
  end
  return manager
end

function M:dumps()
  local Mark = require("fruits.mark.marks")
  local ret = {}
  for flow, submarks in pairs(self.flow_marks) do
    ret[flow] = vim.iter(submarks):map(Mark.dumps):totable()
  end
  return ret
end

function M:sync_needed()
  return self.dirty
end

function M:create_flow(flow)
  if self.flow_marks[flow] then
    return false
  end

  self.flow_marks[flow] = {}
  self.dirty = true
  return true
end

function M:remove_flow(flow)
  if not self.flow_marks[flow] then
    return false
  end

  for _, mark in ipairs(self.flow_marks[flow]) do
    mark:detach(self.ns_id)
    mark:remove(self.path_marks)
  end

  self.flow_marks[flow] = nil
  self.dirty = true
  return true
end

function M:rename_flow(old_name, new_name)
  if not self.flow_marks[old_name] or self.flow_marks[new_name] then
    return false
  end

  self.flow_marks[new_name] = self.flow_marks[old_name]
  self.flow_marks[old_name] = nil
  self.dirty = true
  return true
end

function M:insert_mark(flow, mark)
  local marks = self.flow_marks[flow] or {}
  table.insert(marks, mark)
  self.flow_marks[flow] = marks
  mark:gather(self.path_marks)
  self.dirty = true
  return true
end

function M:remove_mark(flow, index)
  if not self.flow_marks[flow] or #self.flow_marks[flow] < index then
    return false
  end

  --- @type Fruit.mark.Mark
  local mark = table.remove(self.flow_marks[flow], index)
  mark:detach(self.ns_id):remove(self.path_marks)
  self.dirty = true
  return true
end

function M:rename_mark(flow, index, name)
  if not self.flow_marks[flow] or #self.flow_marks[flow] < index then
    return false
  end

  self.flow_marks[flow][index]:rename(name)
  self.dirty = true
  return true
end

function M:attach_path(path, bufnr, hl_group)
  if not self.path_marks[path] then
    return
  end

  for _, mark in ipairs(self.path_marks[path]) do
    mark:attach(self.ns_id, bufnr, hl_group)
  end
end

function M:detach_path(path)
  if not self.path_marks[path] then
    return
  end

  for _, mark in ipairs(self.path_marks[path]) do
    mark:detach(self.ns_id)
  end
end

function M:update_path(path)
  if not self.path_marks[path] then
    return
  end

  for _, mark in ipairs(self.path_marks[path]) do
    self.dirty = self.dirty and mark:update(self.ns_id)
  end
end

function M:list_flows()
  return vim.tbl_keys(self.flow_marks)
end

function M:list_marks(selected)
  return vim
    .iter(self.flow_marks)
    --- @param flow string
    --- @param marks Fruit.mark.Mark[]
    :map(function(flow, marks)
      return {
        name = flow,
        children = vim.iter(marks):map(require("fruits.mark.marks").lookup):totable(),
        extra = {
          selected = flow == selected,
        },
      }
    end)
    :totable()
end

return M
