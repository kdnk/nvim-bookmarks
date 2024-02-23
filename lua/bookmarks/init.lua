local bookmark = require("bookmarks.bookmark")
local sign = require("bookmarks.sign")
local move = require("bookmarks.move")
local sync = require("bookmarks.sync")

local M = {}

function M.reset()
    bookmark.remove_all_bookmarks()
    move.reset_index()
    sign.remove_all_signs()
end

function M.toggle()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local bufnr = vim.api.nvim_get_current_buf()

    if sign.has_signs(bufnr, lnum) then
        sync.delete(bufnr, lnum)
    else
        sync.add(bufnr, lnum)
    end
end

function M.move_next()
    move.move_next()
end

function M.move_prev()
    move.move_prev()
end

return M
