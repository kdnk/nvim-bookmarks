local bookmark = require("bookmarks.bookmark")
local sign = require("bookmarks.sign")
local extmark = require("bookmarks.extmark")

local M = {}

function M.bookmarks_to_signs()
    bookmark.update_bufnr()
    sign.remove_all()

    local bookmarks = bookmark.get_all()
    for _, b in ipairs(bookmarks) do
        sign.add(b.bufnr, b.lnum)
    end
end

---@param bufnr integer
function M.bookmarks_to_extmarks(bufnr)
    extmark.clear_all(bufnr)

    local bs = bookmark.get_by_bufnr(bufnr)
    for _, b in ipairs(bs) do
        local id = extmark.add(bufnr, b.lnum)
        bookmark.update_extmark_id(b.id, id)
    end
end

---@param bufnr integer
function M.extmarks_to_bookmarks(bufnr)
    local bs = bookmark.get_by_bufnr(bufnr)
    local changed = false

    for _, b in ipairs(bs) do
        if b.extmark_id then
            local new_lnum = extmark.get_lnum(bufnr, b.extmark_id)
            if new_lnum and new_lnum ~= b.lnum then
                local old_lnum = b.lnum
                bookmark.update_lnum(b.id, new_lnum)
                changed = true

                -- signも更新
                sign.delete(bufnr, old_lnum)
                sign.add(bufnr, new_lnum)
            end
        end
    end

    if changed then
        require("bookmarks.persist").backup()
    end
end

return M
