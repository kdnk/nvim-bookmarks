local config = require("bookmarks.config")
local bookmark = require("bookmarks.bookmark")

local M = {}

function M.setup()
    if not config.scrollbar.enable then
        return
    end

    require("scrollbar.handlers").register("bookmarks", function(bufnr)
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p")
        -- print("DEBUG: scrollbar handler for " .. filename)
        local filtered_bookmarks = vim.tbl_filter(function(b)
            -- print("DEBUG: comparing with " .. b.filename)
            return b.filename == filename
        end, bookmark.list())
        -- print("DEBUG: matches found: " .. #filtered_bookmarks)
        local marks = vim.tbl_map(function(b)
            return {
                line = b.lnum - 1,
                text = config.scrollbar.text,
                level = 100,
                type = "Info",
            }
        end, filtered_bookmarks)

        return marks
    end)

    local group = vim.api.nvim_create_augroup("nvim-bookmarks.nvim-scrollbar", { clear = true })
    vim.api.nvim_create_autocmd("User", {
        pattern = { "BookmarkAdded", "BookmarkDeleted" },
        callback = function()
            require("scrollbar.handlers").show()
        end,
        group = group,
    })
end

return M
