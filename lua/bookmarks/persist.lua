local bookmark = require("bookmarks.bookmark")
local config = require("bookmarks.config")
local file = require("bookmarks.file")
local sync = require("bookmarks.sync")

local M = {}

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

    sync.bookmarks_to_signs()
end

return M
