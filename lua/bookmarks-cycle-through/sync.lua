local core = require("bookmarks-cycle-through.core")
local bookmark = require("bookmarks-cycle-through.bookmark")
local sign = require("bookmarks-cycle-through.sign")

local M = {}

function M.sync_bookmarks_to_signs()
    sign.remove_all_signs()

    local bookmarks = bookmark.get_bookmarks()
    core.list.each(bookmarks, function(b)
        sign.add_sign(b.bufnr, b.lnum)
    end)
end

---@param bufnr integer
---@param lnum number
function M.delete(bufnr, lnum)
    sign.delete_sign(bufnr, lnum)
    bookmark.delete_bookmark(bufnr, lnum)
end

return M
