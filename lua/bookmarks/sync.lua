local core = require("bookmarks.core")
local bookmark = require("bookmarks.bookmark")
local sign = require("bookmarks.sign")

local M = {}

function M.bookmarks_to_signs()
    sign.remove_all_signs()

    local bookmarks = bookmark.get_bookmarks()
    core.list.each(bookmarks, function(b)
        sign.add(b.bufnr, b.lnum)
    end)
end

return M
