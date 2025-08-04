--- @class Fruit.highlight.actions
--- @field private set fun(ns_id: integer, rs: integer[], re: integer[], hl_group: string | nil): integer
--- @field private reset fun(ns_id: integer, rs: integer[], re: integer[], inverse: boolean): integer
--- @field hl_normal fun(ns_id: integer, hl_group: string): integer
--- @field hl_visual fun(ns_id: integer, hl_group: string): integer
--- @field hl_visual_lines fun(ns_id: integer, hl_group: string): integer
--- @field hl_visual_block fun(ns_id: integer, hl_group: string): integer[]
--- @field reset_hl_normal fun(ns_id: integer): integer
--- @field reset_hl_visual fun(ns_id: integer): integer
--- @field reset_hl_visual_lines fun(ns_id: integer): integer
--- @field reset_hl_visual_block fun(ns_id: integer): integer
local M = {}

local unpack = table.unpack or unpack

local function line_length(bufnr, lnum)
  local lines = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)
  return #lines > 0 and #lines[1] or 0
end

local function get_visual_area()
  local rs = vim.fn.getpos("v")
  local re = vim.fn.getcurpos(0)
  local rsr, rsc = rs[2] - 1, rs[3] - 1
  local rer, rec = re[2] - 1, re[5] - 1

  if rsr < rer then
    return { rsr, rsc, rer, rec }
  end

  if rsr > rer then
    return { rer, rec, rsr, rsc }
  end

  if rsc > rec then
    rsc, rec = rec, rsc
  end

  return { rsr, rsc, rer, rec }
end

--- @type fun(area1: integer[], area2: integer[]): boolean Judges if first area contains the other
local function contains(area1, area2)
  local rsr, rsc, rer, rec = unpack(area1)
  local _rsr, _rsc, _rer, _rec = unpack(area2)
  -- ({ 8, 14, 8, 14 }) contains ({ 7, 0, 9, 48 })
  if rsr > _rsr then
    return false
  end
  if rer < _rer then
    return false
  end
  if rsr == _rsr and rsc > _rsc then
    return false
  end
  if rer == _rer and rec < _rec then
    return false
  end
  return true
end

function M.set(ns_id, rs, re, hl_group)
  return vim.api.nvim_buf_set_extmark(0, ns_id, rs[1], rs[2], {
    end_row = re[1],
    end_col = re[2],
    hl_group = hl_group,
  })
end

function M.reset(ns_id, rs, re, inverse)
  local area1 = { rs[1], rs[2], re[1], re[2] }
  --- @type fun(extmark: vim.api.keyset.get_extmark_item): boolean
  local filter

  if inverse then
    function filter(extmark)
      local area2 = { extmark[2], extmark[3], extmark[4].end_row, extmark[4].end_col - 1 }
      return contains(area2, area1)
    end
  else
    function filter(extmark)
      local area2 = { extmark[2], extmark[3], extmark[4].end_row, extmark[4].end_col - 1 }
      return contains(area1, area2)
    end
  end

  --- @type fun(extmark: vim.api.keyset.get_extmark_item): integer
  local function executor(extmark)
    if not vim.api.nvim_buf_del_extmark(0, ns_id, extmark[1]) then
      vim.notify(("(%d, %d) removing failed"):format(ns_id, extmark[1]), vim.log.levels.ERROR)
    end
    return extmark[1]
  end

  return #vim
    .iter(vim.api.nvim_buf_get_extmarks(0, ns_id, 0, -1, { details = true }))
    :filter(filter)
    :map(executor)
    :totable()
end

function M.hl_normal(ns_id, hl_group)
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local length = line_length(0, row)
  return M.set(ns_id, { row, 0 }, { row, length }, hl_group)
end

function M.hl_visual(ns_id, hl_group)
  local rsr, rsc, rer, rec = unpack(get_visual_area())
  local length = line_length(0, rer)
  return M.set(ns_id, { rsr, rsc }, { rer, math.min(rec + 1, length) }, hl_group)
end

function M.hl_visual_lines(ns_id, hl_group)
  local rsr, _, rer, _ = unpack(get_visual_area())
  local length = line_length(0, rer)
  return M.set(ns_id, { rsr, 0 }, { rer, length }, hl_group)
end

function M.hl_visual_block(ns_id, hl_group)
  local rsr, rsc, rer, rec = unpack(get_visual_area())
  if rsc > rec then
    rsc, rec = rec, rsc
  end
  local mark_ids = {}
  for lnum = rsr, rer, 1 do
    local length = line_length(0, lnum)
    if length > rec then
      table.insert(mark_ids, M.set(ns_id, { lnum, rsc }, { lnum, rec + 1 }, hl_group))
    elseif length > rsc then
      table.insert(mark_ids, M.set(ns_id, { lnum, rsc }, { lnum, length }, hl_group))
    end
  end
  return mark_ids
end

function M.reset_hl_normal(ns_id)
  local pos = vim.fn.getcurpos(0)
  local lnum, cnum = pos[2] - 1, pos[3] - 1
  return M.reset(ns_id, { lnum, cnum }, { lnum, cnum }, true)
end

function M.reset_hl_visual(ns_id)
  local rsr, rsc, rer, rec = unpack(get_visual_area())
  return M.reset(ns_id, { rsr, rsc }, { rer, rec }, false)
end

function M.reset_hl_visual_lines(ns_id)
  local rsr, _, rer, _ = unpack(get_visual_area())
  local length = line_length(0, rer)
  return M.reset(ns_id, { rsr, 0 }, { rer, length }, false)
end

function M.reset_hl_visual_block(ns_id)
  local rsr, rsc, rer, rec = unpack(get_visual_area())
  if rsc > rec then
    rsc, rec = rec, rsc
  end
  local counter = 0
  for lnum = rsr, rer do
    counter = counter + M.reset(ns_id, { lnum, rsc }, { lnum, rec }, false)
  end
  return counter
end

return M
