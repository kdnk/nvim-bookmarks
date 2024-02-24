local core = require("bookmarks.core")
local config = require("bookmarks.config")
local file = require("bookmarks.file")

local M = {}

---@class Bookmark
---@field filename string
---@field bufnr integer
---@field lnum number

---@type Bookmark[]
local bookmarks = {}

local function update_bufnr()
    core.list.each(bookmarks, function(bookmark)
        local bufnr = vim.fn.bufadd(bookmark.filename)
        bookmark.bufnr = bufnr
    end)
end

---@return Bookmark[]
function M.get_bookmarks()
    update_bufnr()

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

function M.update_bookmarks(bs)
    bookmarks = bs
end

---@param bufnr integer
---@param lnum number
---@return nil
function M.add_bookmark(bufnr, lnum)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    table.insert(bookmarks, { filename = filename, bufnr = bufnr, lnum = lnum })
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
end

function M.remove_all_bookmarks()
    bookmarks = {}
end

function M.serialize()
    update_bufnr()
    return { vim.json.encode(M.get_bookmarks()) }
end

---@return Bookmark[]
function M.deserialize()
    if not file.exists(config.serialize_path) then
        return {}
    end

    local json = vim.fn.readfile(config.serialize_path)
    if json == nil then
        return {}
    else
        return vim.json.decode(json[1]) or {}
    end
end

return M
