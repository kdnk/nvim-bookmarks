local bookmark = require("bookmarks.bookmark")
local move = require("bookmarks.move")
local M = {}

function M.bookmark_count()
    local bookmarks = bookmark.get_bookmarks()
    if #bookmarks == 0 then
        return "0/0"
    end
    return move.get_index() .. "/" .. #bookmarks
end

return M
