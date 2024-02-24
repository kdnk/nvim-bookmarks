local bookmark = require("bookmarks.bookmark")
local sign = require("bookmarks.sign")
local jump = require("bookmarks.jump")
local sync = require("bookmarks.sync")
local config = require("bookmarks.config")

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
        sign.delete(bufnr, lnum)
        bookmark.delete(bufnr, lnum)
    else
        sign.add(bufnr, lnum)
        bookmark.add(bufnr, lnum)
    end
end

function M.jump_next()
    jump.jump({ reverse = false })
end

function M.jump_prev()
    jump.jump({ reverse = true })
end

---@param opts? Config
function M.setup(opts)
    config.setup(opts)
end

return M
