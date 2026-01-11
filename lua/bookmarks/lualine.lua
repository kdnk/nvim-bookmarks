local bookmark = require("bookmarks.bookmark")
local jump = require("bookmarks.jump")
local M = {}

function M.bookmark_count()
    local bookmarks = bookmark.list()
    local total = #bookmarks
    if total == 0 then
        return string.format("%7s", "⚑ 0/0")
    end
    local index = jump.get_index()
    local display_index = index == 0 and "-" or tostring(index)
    return string.format("%7s", "⚑ " .. display_index .. "/" .. total)
end

return M
