local config = require("bookmarks.config")
local bookmark = require("bookmarks.bookmark")
local sign = require("bookmarks.sign")
local extmark = require("bookmarks.extmark")
local jump = require("bookmarks.jump")
local persist = require("bookmarks.persist")
local autocmd = require("bookmarks.autocmd")

local M = {}

function M.reset()
    bookmark.remove_all()
    sign.remove_all()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(bufnr) then
            extmark.clear_all(bufnr)
        end
    end
    jump.reset_index()
    persist.backup()
end

function M.toggle()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local bufnr = vim.api.nvim_get_current_buf()

    if bookmark.exists(bufnr, lnum) then
        bookmark.delete(bufnr, lnum)
    else
        bookmark.add(bufnr, lnum)
    end
end

function M.jump_next()
    jump.jump({ reverse = false })
end

function M.jump_prev()
    jump.jump({ reverse = true })
end

function M.backup()
    persist.backup()
end

function M.restore()
    persist.restore()
end

---@param opts? Config
function M.setup(opts)
    config.setup(opts)
    autocmd.setup()
end

return M
