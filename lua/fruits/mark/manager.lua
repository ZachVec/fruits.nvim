--- @class Fruit.mark.Manager
--- @field flow_marks table<string, Fruit.mark.Mark[]> flow -> marks mapping
--- @field path_marks table<string, Fruit.mark.Mark[]> path -> marks mapping
--- @field new fun(): Fruit.mark.Manager
--- @field load fun(marks: table<string, Fruit.mark.SerializedMark[]>): Fruit.mark.Manager
--- @field dump fun(self: Fruit.mark.Manager): table<string, Fruit.mark.SerializedMark[]>
--- @field list fun(self: Fruit.mark.Manager, ns_id: integer): Fruit.mark.FlowView[]
--- @field each_flow fun(self: Fruit.mark.Manager, fn: fun(path: string, marks: Fruit.mark.Mark[]))
--- @field each_mark fun(self: Fruit.mark.Manager, path: string, fn: fun(mark: Fruit.mark.Mark))
--- @field create_flow fun(self: Fruit.mark.Manager, flow: string): boolean Create a new flow
--- @field remove_flow fun(self: Fruit.mark.Manager, flow: string): Fruit.mark.Mark[] | nil Remove an existing flow
--- @field rename_flow fun(self: Fruit.mark.Manager, old_name: string, new_name: string): boolean Rename an existing flow
--- @field insert_mark fun(self: Fruit.mark.Manager, flow: string, mark: Fruit.mark.Mark): boolean Insert a mark into a flow
--- @field remove_mark fun(self: Fruit.mark.Manager, flow: string, index: integer): Fruit.mark.Mark | nil Remove a mark from a flow by index
--- @field rename_mark fun(self: Fruit.mark.Manager, flow: string, index: integer, name: string): boolean Rename a mark in a flow by index
local M = {}

function M.new()
  return setmetatable({
    flow_marks = {},
    path_marks = {},
  }, { __index = M })
end

function M.load(marks)
  local Mark = require("fruits.mark.marks")
  local manager = M.new()
  for flow, submarks in pairs(marks) do
    manager:create_flow(flow)
    vim.iter(submarks):map(Mark.load):each(function(mark)
      manager:insert_mark(flow, mark)
    end)
  end
  return manager
end

function M:dump()
  local Mark = require("fruits.mark.marks")
  local ret = {}
  for flow, submarks in pairs(self.flow_marks) do
    ret[flow] = vim.iter(submarks):map(Mark.dump):totable()
  end
  return ret
end

function M:list(ns_id)
  return vim
    .iter(self.flow_marks)
    --- @param flow string
    --- @param marks Fruit.mark.Mark[]
    :map(function(flow, marks)
      return {
        name = flow,
        children = vim
          .iter(marks)
          --- @param mark Fruit.mark.Mark
          :map(function(mark)
            return mark:list(ns_id)
          end)
          :totable(),
        extra = {},
      }
    end)
    :totable()
end

function M:each_flow(fn)
  vim.iter(self.path_marks):each(fn)
end

function M:each_mark(path, fn)
  vim.iter(self.path_marks[path] or {}):each(fn)
end

function M:create_flow(flow)
  if self.flow_marks[flow] then
    return false
  end
  self.flow_marks[flow] = {}
  return true
end

function M:remove_flow(flow)
  if not self.flow_marks[flow] then
    return nil
  end

  local marks = self.flow_marks[flow]
  for _, mark in ipairs(marks) do
    self.path_marks[mark.path] = vim
      .iter(self.path_marks[mark.path])
      :filter(
        --- @param m Fruit.mark.Mark
        function(m)
          return m ~= mark
        end
      )
      :totable()
  end
  self.flow_marks[flow] = nil
  return marks
end

function M:rename_flow(old_name, new_name)
  if not self.flow_marks[old_name] or self.flow_marks[new_name] then
    return false
  end
  self.flow_marks[new_name] = self.flow_marks[old_name]
  self.flow_marks[old_name] = nil
  return true
end

function M:insert_mark(flow, mark)
  if not self.flow_marks[flow] then
    return false
  end

  local marks = self.flow_marks[flow]
  table.insert(marks, mark)
  self.flow_marks[flow] = marks
  local path_marks = self.path_marks[mark.path] or {}
  table.insert(path_marks, mark)
  self.path_marks[mark.path] = path_marks
  return true
end

function M:remove_mark(flow, index)
  if not self.flow_marks[flow] or #self.flow_marks[flow] < index then
    return nil
  end

  --- @type Fruit.mark.Mark
  local mark = table.remove(self.flow_marks[flow], index)
  self.path_marks[mark.path] = vim
    .iter(self.path_marks[mark.path])
    :filter(
      --- @param m Fruit.mark.Mark
      function(m)
        return m ~= mark
      end
    )
    :totable()
  return mark
end

function M:rename_mark(flow, index, name)
  if not self.flow_marks[flow] or #self.flow_marks[flow] < index then
    return false
  end

  self.flow_marks[flow][index]:rename(name)
  self.dirty = true
  return true
end
--
-- function M:attach_path(path, bufnr, sign_text)
--   if not self.path_marks[path] then
--     return false
--   end
--
--   for _, mark in ipairs(self.path_marks[path]) do
--     mark:attach(self.ns_id, bufnr, sign_text)
--   end
--   return true
-- end
--
-- function M:detach_path(path)
--   --- @type table<string, Fruit.mark.Mark[]>
--   local marks
--
--   if not path then
--     marks = self.path_marks
--   elseif not self.path_marks[path] then
--     return false
--   else
--     marks = { path = self.path_marks[path] }
--   end
--
--   for _, _marks in pairs(marks) do
--     for _, mark in ipairs(_marks) do
--       mark:detach(self.ns_id)
--     end
--   end
--
--   return true
-- end
--
return M
