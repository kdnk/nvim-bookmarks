local bookmark = require("bookmarks.bookmark")
local sign = require("bookmarks.sign")
local extmark = require("bookmarks.extmark")

local M = {}

function M.bookmarks_to_signs()
    bookmark.update_bufnr()
    sign.remove_all()

    local bookmarks = bookmark.list()
    for _, b in ipairs(bookmarks) do
        sign.add(b.bufnr, b.lnum)
    end
end

---@param bufnr integer
function M.bookmarks_to_extmarks(bufnr)
    bookmark.update_bufnr()
    extmark.clear_all(bufnr)

    local bookmarks = bookmark.list()
    local filename = vim.api.nvim_buf_get_name(bufnr)
    for _, b in ipairs(bookmarks) do
        if b.filename == filename then
            local id = extmark.add(bufnr, b.lnum)
            bookmark.update_extmark_id(filename, b.lnum, id)
        end
    end
end

---@param bufnr integer
function M.extmarks_to_bookmarks(bufnr)
    local bs = bookmark.list()
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local changed = false

    for _, b in ipairs(bs) do
        if b.filename == filename and b.extmark_id then
            local new_lnum = extmark.get_lnum(bufnr, b.extmark_id)
            if new_lnum and new_lnum ~= b.lnum then
                local old_lnum = b.lnum
                b.lnum = new_lnum
                changed = true

                -- signも更新
                sign.delete(bufnr, old_lnum)
                sign.add(bufnr, new_lnum)
            end
        end
    end

    if changed then
        bookmark.update_all(bs)
        require("bookmarks.persist").backup()
    end
end

return M
