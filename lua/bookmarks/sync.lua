local core = require("bookmarks.core")
local bookmark = require("bookmarks.bookmark")
local sign = require("bookmarks.sign")
local extmark = require("bookmarks.extmark")

local M = {}

function M.bookmarks_to_signs()
    sign.remove_all()

    local bookmarks = bookmark.list()
    core.lua.list.each(bookmarks, function(b)
        sign.add(b.bufnr, b.lnum)
    end)
end

---@param bufnr integer
function M.bookmarks_to_extmarks(bufnr)
    extmark.clear_buffer(bufnr)

    local bookmarks = bookmark.list()
    core.lua.list.each(bookmarks, function(b)
        if b.bufnr == bufnr then
            extmark.add(b.bufnr, b.lnum)
        end
    end)
end

---@param bufnr integer
function M.extmarks_to_bookmarks(bufnr)
    local changes = extmark.get_position_changes(bufnr)

    for old_lnum, new_lnum in pairs(changes) do
        -- bookmarkの行番号を更新
        local bs = bookmark.list()
        core.lua.list.each(bs, function(b, index)
            if b.bufnr == bufnr and b.lnum == old_lnum then
                bs[index].lnum = new_lnum
            end
        end)
        bookmark.update_all(bs)

        -- extmarkの内部管理も更新
        extmark.update_lnum(bufnr, old_lnum, new_lnum)

        -- signも更新
        sign.delete(bufnr, old_lnum)
        sign.add(bufnr, new_lnum)
    end
end

return M
