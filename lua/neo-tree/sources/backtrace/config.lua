local M = {}

--- @class Traceback.Config
local defaults = {
  dir = vim.fn.stdpath("state") .. "/traceback/",
  branch = true, -- use git branch to save sessions
}

--- @class Traceback.Config
M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, defaults, opts or {})
end

return M
