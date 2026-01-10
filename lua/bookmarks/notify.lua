local M = {}

---@param msg string
---@param level integer|nil
---@param opts table|nil
local function notify(msg, level, opts)
    vim.notify(string.format("[nvim-bookmarks] %s", msg), level, opts)
end

function M.info(msg, opts)
    notify(msg, vim.log.levels.INFO, opts)
end

function M.warn(msg, opts)
    notify(msg, vim.log.levels.WARN, opts)
end

function M.error(msg, opts)
    notify(msg, vim.log.levels.ERROR, opts)
end

function M.debug(msg, opts)
    notify(msg, vim.log.levels.DEBUG, opts)
end

return M
