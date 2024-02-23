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

-- ---@param index integer
-- function M.normalize_bookmarks(index)
--     local bookmarks = M.get_bookmarks()
--     local b = bookmarks[index]
--     local max_lnum = vim.api.nvim_buf_line_count(b.bufnr)
--     if max_lnum < b.lnum then
--         M.delete(b.bufnr, b.lnum)
--         M.sync_bookmarks_to_signs()
--     end
-- end

---@param bufnr integer
---@param lnum number
function M.delete(bufnr, lnum)
    sign.delete_sign(bufnr, lnum)
    bookmark.delete_bookmark(bufnr, lnum)
end

function M.write()
    local json = bookmark.serialize()
    vim.fn.writefile(json, vim.g.bookmark_serialize_path)
end

function M.read()
    bookmark.update_bookmarks(bookmark.deserialize())
    print("[sync.lua:30] bookmar: " .. vim.inspect(bookmark))
    M.sync_bookmarks_to_signs()
end

return M
