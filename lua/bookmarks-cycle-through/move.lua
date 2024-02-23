local bookmark = require("bookmarks-cycle-through.bookmark")
local M = {}

M.index = 1

local function move_cursor(file, line)
    local bufnr = vim.fn.bufnr(file, true)
    vim.api.nvim_set_current_buf(bufnr)

    local win_id = vim.api.nvim_get_current_win()

    vim.api.nvim_win_set_cursor(win_id, { line, 0 })
end

local function increase_index()
    local bookmarks = bookmark.get_bookmarks()
    M.index = M.index + 1
    if M.index > #bookmarks then
        M.index = 1
    end
end

local function decrease_index()
    local bookmarks = bookmark.get_bookmarks()
    M.index = M.index - 1
    if M.index <= 0 then
        M.index = #bookmarks
    end
end

function M.move_prev()
    local bookmarks = bookmark.get_bookmarks()
    decrease_index()

    local b = bookmarks[M.index]
    move_cursor(b.filename, b.lnum)
end

function M.move_next()
    local bookmarks = bookmark.get_bookmarks()
    increase_index()

    local b = bookmarks[M.index]
    print("[move.lua:44] M.index: " .. vim.inspect(M.index))
    move_cursor(b.filename, b.lnum)
end

return M
