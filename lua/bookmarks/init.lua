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

    -- Handle bookmark additions
    vim.api.nvim_create_autocmd("User", {
        pattern = "BookmarkAdded",
        callback = function()
            local bufnr = vim.api.nvim_get_current_buf()
            -- We need the lnum of the added bookmark. 
            -- Currently bookmark.add doesn't pass it in the event, but toggle uses cursor pos.
            -- A better approach for the event handler might be to sync all or pass data.
            -- For now, let's sync everything or assume cursor context if we want to be precise, 
            -- BUT syncing everything is safer and simpler for consistency.
            -- Actually, let's look at what toggle did: it added sign and extmark at specific lnum.
            -- `sync.bookmarks_to_signs` and `sync.bookmarks_to_extmarks` do full sync.
            
            -- Let's use full sync for robustness for now, optimization can come later if needed.
            sync.bookmarks_to_signs()
            sync.bookmarks_to_extmarks(bufnr)
            persist.backup()
        end,
    })

    -- Handle bookmark deletions
    vim.api.nvim_create_autocmd("User", {
        pattern = "BookmarkDeleted",
        callback = function()
            local bufnr = vim.api.nvim_get_current_buf()
            sync.bookmarks_to_signs()
            sync.bookmarks_to_extmarks(bufnr)
            persist.backup()
        end,
    })
end

return M
