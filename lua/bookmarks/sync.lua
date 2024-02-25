local core = require("bookmarks.core")
local bookmark = require("bookmarks.bookmark")
local sign = require("bookmarks.sign")

local M = {}

function M.bookmarks_to_signs()
    sign.remove_all()

    local bookmarks = bookmark.list()
    core.lua.list.each(bookmarks, function(b)
        sign.add(b.bufnr, b.lnum)
    end)
end

return M
