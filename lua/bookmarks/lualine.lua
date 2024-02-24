local bookmark = require("bookmarks.bookmark")
local jump = require("bookmarks.jump")
local M = {}

function M.bookmark_count()
    local bookmarks = bookmark.list()
    if #bookmarks == 0 then
        return "0/0"
    end
    return jump.get_index() .. "/" .. #bookmarks
end

return M
