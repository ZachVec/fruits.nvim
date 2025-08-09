--- @class Fruit.mark.Mark
--- @field path string
--- @field name string
--- @field lnum integer
--- @field cnum integer
--- @field info { bufnr: integer, markid: integer } | nil
--- @field new fun(path: string, name: string, lnum: integer, cnum: integer): Fruit.mark.Mark
--- @field load fun(mark: Fruit.mark.SerializedMark): Fruit.mark.Mark
--- @field dump fun(self: Fruit.mark.Mark): Fruit.mark.SerializedMark
--- @field list fun(self: Fruit.mark.Mark, ns_id: integer): Fruit.mark.MarkView
--- @field rename fun(self: Fruit.mark.Mark, name: string): nil
--- @field attach fun(self: Fruit.mark.Mark, ns_id: integer, bufnr: integer, sign_text: string | nil): nil
--- @field detach fun(self: Fruit.mark.Mark, ns_id: integer): boolean
local M = {}

function M.new(path, name, lnum, cnum)
  return setmetatable({
    path = path,
    name = name,
    lnum = lnum,
    cnum = cnum,
  }, { __index = M })
end

function M.load(mark)
  return M.new(mark.path, mark.name, mark.lnum, mark.cnum)
end

function M:dump()
  return { path = self.path, name = self.name, lnum = self.lnum, cnum = self.cnum }
end

function M:list(ns_id)
  local extra
  if self.info then
    extra = {
      mark = {
        bufnr = self.info.bufnr,
        ns_id = ns_id,
        markid = self.info.markid,
      },
    }
  else
    extra = {
      position = { self.lnum, self.cnum },
    }
  end
  return { name = self.name, path = self.path, extra = extra }
end

function M:rename(name)
  self.name = name
end

function M:attach(ns_id, bufnr, sign_text)
  if self.info ~= nil then
    vim.notify(("Already attached to buffer %d"):format(self.info.bufnr), vim.log.levels.WARN)
    return
  end
  assert(bufnr >= 0, ("Attach to an invalid buffer %d"):format(bufnr))
  bufnr = bufnr > 0 and bufnr or vim.api.nvim_get_current_buf()
  local success, markid = pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, self.lnum, self.cnum, {
    sign_text = sign_text,
    sign_hl_group = "FruitMarkSign",
    line_hl_group = "FruitMarkLine",
  })
  if not success then
    local path = vim.api.nvim_buf_get_name(bufnr)
    local content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    vim.notify(
      ("[%d %s] Failed to attach (%d, %d), buffer content\n%s"):format(
        bufnr,
        path,
        self.lnum,
        self.cnum,
        table.concat(content, "\n")
      ),
      vim.log.levels.ERROR
    )
    return
  end
  self.info = {
    bufnr = bufnr,
    markid = markid,
  }
end

function M:detach(ns_id)
  if not self.info then
    return false
  end

  local bufnr, markid = self.info.bufnr, self.info.markid
  local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_id, markid, {})
  self.lnum, self.cnum = (table.unpack or unpack)(mark)
  self.info = nil
  assert(vim.api.nvim_buf_del_extmark(bufnr, ns_id, markid), "invalid markid")
  return true
end

return M
