local sync = require("bookmarks.sync")
local persist = require("bookmarks.persist")

local M = {}

function M.setup()
    local group = vim.api.nvim_create_augroup("nvim-bookmarks", { clear = true })

    -- buffer load時にextmarkを作成
    vim.api.nvim_create_autocmd("BufReadPost", {
        group = group,
        callback = function(args)
            local bufnr = args.buf
            sync.bookmarks_to_extmarks(bufnr)
        end,
    })

    -- buffer変更時にextmarkの位置変更をsignに反映
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        group = group,
        callback = function(args)
            local bufnr = args.buf
            sync.extmarks_to_bookmarks(bufnr)
        end,
    })

    -- Handle bookmark additions
    vim.api.nvim_create_autocmd("User", {
        pattern = "BookmarkAdded",
        group = group,
        callback = function()
            local bufnr = vim.api.nvim_get_current_buf()
            sync.bookmarks_to_signs()
            sync.bookmarks_to_extmarks(bufnr)
            persist.backup()
        end,
    })

    -- Handle bookmark deletions
    vim.api.nvim_create_autocmd("User", {
        pattern = "BookmarkDeleted",
        group = group,
        callback = function()
            local bufnr = vim.api.nvim_get_current_buf()
            sync.bookmarks_to_signs()
            sync.bookmarks_to_extmarks(bufnr)
            persist.backup()
        end,
    })
end

return M
