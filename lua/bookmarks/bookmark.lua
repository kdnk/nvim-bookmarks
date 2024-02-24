local core = require("bookmarks.core")

local M = {}

---@class Bookmark
---@field filename string
---@field bufnr integer
---@field lnum number

---@type Bookmark[]
local bookmarks = {}

function M.update_bufnr()
    core.list.each(bookmarks, function(bookmark)
        local bufnr = vim.fn.bufadd(bookmark.filename)
        bookmark.bufnr = bufnr
    end)
end

---@return Bookmark[]
function M.list()
    M.update_bufnr()

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

function M.update_all(bs)
    bookmarks = bs
end

---@param bufnr integer
---@param lnum number
---@return nil
function M.add(bufnr, lnum)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    table.insert(bookmarks, { filename = filename, bufnr = bufnr, lnum = lnum })
end

---@param bufnr integer
---@param lnum number
---@return nil
function M.delete(bufnr, lnum)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    core.list.each(bookmarks, function(bookmark, index)
        if bookmark.filename == filename and bookmark.lnum == lnum then
            table.remove(bookmarks, index)
        end
    end)
end

function M.remove_all_bookmarks()
    bookmarks = {}
end

---@return any
function M.toJson()
    return { vim.json.encode(M.list()) }
end

---@param json any[]
---@return Bookmark[]
function M.fromJson(json)
    if json == nil then
        return {}
    else
        return vim.json.decode(json[1]) or {} --[[ @as Bookmark[] ]]
    end
end

return M
