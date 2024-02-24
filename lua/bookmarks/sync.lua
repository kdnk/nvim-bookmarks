local core = require("bookmarks.core")
local bookmark = require("bookmarks.bookmark")
local sign = require("bookmarks.sign")
local config = require("bookmarks.config")
local file = require("bookmarks.file")

local M = {}

function M.sync_bookmarks_to_signs()
    sign.remove_all_signs()

    local bookmarks = bookmark.get_bookmarks()
    core.list.each(bookmarks, function(b)
        sign.add_sign(b.bufnr, b.lnum)
    end)
end

---@param bufnr integer
---@param lnum number
function M.add(bufnr, lnum)
    sign.add_sign(bufnr, lnum)
    bookmark.add_bookmark(bufnr, lnum)
end

---@param bufnr integer
---@param lnum number
function M.delete(bufnr, lnum)
    sign.delete_sign(bufnr, lnum)
    bookmark.delete_bookmark(bufnr, lnum)
end

function M.write()
    if config.persist then
        bookmark.update_bufnr()
        local json = bookmark.toJson()
        file.json_write(json, config.serialize_path)
    end
end

function M.read()
    if not config.persist then
        return {}
    end

    if not file.exists(config.serialize_path) then
        return {}
    end

    local json = file.json_read(config.serialize_path)
    local bookmarks = bookmark.fromJson(json)
    bookmark.update_bookmarks(bookmarks)

    M.sync_bookmarks_to_signs()
end

return M
