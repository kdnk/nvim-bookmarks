local config = require("bookmarks.config")
local bookmark = require("bookmarks.bookmark")
local sign = require("bookmarks.sign")
local extmark = require("bookmarks.extmark")
local jump = require("bookmarks.jump")
local persist = require("bookmarks.persist")
local sync = require("bookmarks.sync")

local M = {}

function M.reset()
    bookmark.remove_all()
    sign.remove_all()
    extmark.clear_all()
    jump.reset_index()
    persist.backup()
end

function M.toggle()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local bufnr = vim.api.nvim_get_current_buf()

    if bookmark.exists(bufnr, lnum) then
        sign.delete(bufnr, lnum)
        extmark.delete(bufnr, lnum)
        bookmark.delete(bufnr, lnum)
    else
        sign.add(bufnr, lnum)
        extmark.add(bufnr, lnum)
        bookmark.add(bufnr, lnum)
    end
    persist.backup()
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

    -- buffer load時にextmarkを作成
    vim.api.nvim_create_autocmd("BufReadPost", {
        callback = function(args)
            local bufnr = args.buf
            sync.bookmarks_to_extmarks(bufnr)
        end,
    })

    -- buffer変更時にextmarkの位置変更をsignに反映
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        callback = function(args)
            local bufnr = args.buf
            sync.extmarks_to_bookmarks(bufnr)
        end,
    })
end

return M
