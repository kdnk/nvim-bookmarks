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
            sync.refresh(bufnr)
        end,
    })

    -- Handle bookmark deletions
    vim.api.nvim_create_autocmd("User", {
        pattern = "BookmarkDeleted",
        group = group,
        callback = function()
            local bufnr = vim.api.nvim_get_current_buf()
            sync.refresh(bufnr)
        end,
    })

    -- Handle bookmark restoration
    vim.api.nvim_create_autocmd("User", {
        pattern = "BookmarkRestored",
        group = group,
        callback = function()
            sync.bookmarks_to_signs()
            -- 全てのバッファに対してextmarkを作成（現在開いているもの）
            for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(bufnr) then
                    sync.bookmarks_to_extmarks(bufnr)
                end
            end
        end,
    })
end

return M
