local core = require("bookmarks-cycle-through.core")
local M = {}

---@class Bookmark
---@field filename number
---@field bufnr integer
---@field lnum number[]

---@type Bookmark[]
M.bookmarks = {}

---@param bufnr integer
---@param lnum number
---@return nil
function M.add_bookmark(bufnr, lnum)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    table.insert(M.bookmarks, { filename = filename, bufnr = bufnr, lnum = lnum })
end

---@param bufnr integer
---@param lnum number
---@return nil
function M.delete_bookmark(bufnr, lnum)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    core.list.each(M.bookmarks, function(bookmark, index)
        if bookmark.filename == filename and bookmark.lnum == lnum then
            table.remove(M.bookmarks, index)
        end
    end)
end

return M
