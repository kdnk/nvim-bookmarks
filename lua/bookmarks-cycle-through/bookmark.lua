local core = require("bookmarks-cycle-through.core")
local M = {}

---@class Bookmark
---@field filename number
---@field bufnr integer
---@field lnum number

---@type Bookmark[]
local bookmarks = {}

---@return Bookmark[]
function M.get_bookmarks()
    local filenames = core.list.uniq(core.list.map(bookmarks, function(bookmark)
        return bookmark.filename
    end))

    local new_bookmarks = {}
    core.list.each(filenames, function(filename)
        local bs = core.list.sort(
            core.list.filter(bookmarks, function(bookmark)
                return bookmark.filename == filename
            end),
            function(prev, next)
                return prev.lnum > next.lnum
            end
        )
        core.list.each(bs, function(bookmark)
            table.insert(new_bookmarks, bookmark)
        end)
    end)

    return new_bookmarks
end

---@param bufnr integer
---@param lnum number
---@return nil
function M.add_bookmark(bufnr, lnum)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    table.insert(bookmarks, { filename = filename, bufnr = bufnr, lnum = lnum })

    M.get_bookmarks()
end

---@param bufnr integer
---@param lnum number
---@return nil
function M.delete_bookmark(bufnr, lnum)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    core.list.each(bookmarks, function(bookmark, index)
        if bookmark.filename == filename and bookmark.lnum == lnum then
            table.remove(bookmarks, index)
        end
    end)
    M.get_bookmarks()
end

return M
