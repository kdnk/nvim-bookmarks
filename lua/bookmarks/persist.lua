local bookmark = require("bookmarks.bookmark")
local config = require("bookmarks.config")
local file = require("bookmarks.file")
local sync = require("bookmarks.sync")

local M = {}

function M.write()
    if config.persist.enable then
        bookmark.update_bufnr()
        local json = bookmark.toJson()
        file.json_write(json, config.persist.path)
    end
end

function M.read()
    if not config.persist.enable then
        return {}
    end

    if not file.exists(config.persist.path) then
        return {}
    end

    local json = file.json_read(config.persist.path)
    local bookmarks = bookmark.fromJson(json)
    bookmark.update_bookmarks(bookmarks)

    sync.bookmarks_to_signs()
end

return M
