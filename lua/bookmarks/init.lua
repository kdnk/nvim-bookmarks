local bookmark = require("bookmarks.bookmark")
local sign = require("bookmarks.sign")
local jump = require("bookmarks.jump")
local sync = require("bookmarks.sync")

local M = {}

function M.reset()
    bookmark.remove_all_bookmarks()
    sign.remove_all_signs()
    jump.reset_index()
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

function M.jump_next()
    jump.jump({ reverse = false })
end

function M.jump_prev()
    jump.jump({ reverse = true })
end

return M
