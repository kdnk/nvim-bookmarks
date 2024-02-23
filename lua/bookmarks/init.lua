local bookmark = require("bookmarks.bookmark")
local sign = require("bookmarks.sign")
local move = require("bookmarks.move")

local M = {}

function M.reset()
    bookmark.remove_all_bookmarks()
    move.reset_index()
    sign.remove_all_signs()
end

function M.toggle()
    sign.toggle()
end

function M.move_next()
    move.move_next()
end

function M.move_prev()
    move.move_prev()
end

return M
