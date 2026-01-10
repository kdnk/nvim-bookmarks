local config = require("bookmarks.config")
local bookmark = require("bookmarks.bookmark")

local M = {}

function M.setup()
    if not config.scrollbar.enable then
        return
    end

    require("scrollbar.handlers").register("bookmarks", function(bufnr)
        local filtered_bookmarks = vim.tbl_filter(function(b)
            return b.bufnr == bufnr
        end, bookmark.list())
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
