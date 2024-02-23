local core = require("bookmarks-cycle-through.core")
local M = {}

---@class Bookmark
---@field filename number
---@field bufnr integer
---@field lnum number

---@type Bookmark[]
local bookmarks = {}

---@alias BookmarkByFile table<string, Bookmark[]>
---@return BookmarkByFile
function M.retrieve_bookmarks()
    ---@type BookmarkByFile
    local bookmarks_by_file = {}

    core.list.each(bookmarks, function(bookmark)
        if core.table.is_empty(bookmarks_by_file[bookmark.filename] or {}) then
            bookmarks_by_file[bookmark.filename] = { bookmark }
        else
            table.insert(bookmarks_by_file[bookmark.filename], bookmark)
        end
    end)
    core.table.each(bookmarks_by_file, function(filename, bs)
        bookmarks_by_file[filename] = core.list.sort(bs, function(prev, next)
            return prev.lnum > next.lnum
        end)
    end)
    return bookmarks_by_file
end

---@param bufnr integer
---@param lnum number
---@return nil
function M.add_bookmark(bufnr, lnum)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    table.insert(bookmarks, { filename = filename, bufnr = bufnr, lnum = lnum })

    M.retrieve_bookmarks()
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
    M.retrieve_bookmarks()
end
