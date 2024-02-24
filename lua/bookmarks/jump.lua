local core = require("bookmarks.core")
local bookmark = require("bookmarks.bookmark")
local sync = require("bookmarks.sync")
local file = require("bookmarks.file")

local M = {}

local index = 1

---@param opts { reverse: boolean }
---@return integer
local function move_index(opts)
    local bookmarks = bookmark.get_bookmarks()
    if not opts.reverse then
        index = index + 1
        if #bookmarks < index then
            index = 1
        end
    else
        index = index - 1
        if index <= 0 then
            index = #bookmarks
        end
    end
    return index
end

---@param i integer
---@return boolean
local function is_valid_bookmark(i)
    local bookmarks = bookmark.get_bookmarks()
    local b = bookmarks[i]
    local max_lnum = file.get_max_lnum(b.filename)

    return b.lnum < max_lnum
end

---@param opts { reverse: boolean }
---@return integer
local function sanitize_bookmark(opts)
    local bookmarks = bookmark.get_bookmarks()
    local b = bookmarks[index]

    if is_valid_bookmark(index) then
        return index
    end

    bookmark.delete(b.bufnr, b.lnum)
    sync.sync_bookmarks_to_signs()

    bookmarks = bookmark.get_bookmarks()
    if not opts.reverse then
        index = #bookmarks < index and 1 or index
        if is_valid_bookmark(index) then
            return index
        else
            return sanitize_bookmark(opts)
        end
    else
        index = move_index(opts)
        if is_valid_bookmark(index) then
            return index
        else
            return sanitize_bookmark(opts)
        end
    end
end

---@param opts { reverse: boolean }
---@return nil
local function jump_cursor(opts)
    index = sanitize_bookmark(opts)
    local bookmarks = bookmark.get_bookmarks()
    local b = bookmarks[index]
    vim.api.nvim_set_current_buf(b.bufnr)
    local win_id = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_cursor(win_id, { b.lnum, 0 })
end

---@param filename string
---@param lnum integer
---@return { prev: integer, next: integer }
local function get_neighboring_bookmarks(filename, lnum)
    local bookmarks = bookmark.get_bookmarks()

    local prev = core.list.find_last_index(bookmarks, function(b)
        return filename == b.filename and b.lnum < lnum
    end)
    local next = core.list.find_index(bookmarks, function(b)
        return b.filename == filename and lnum < b.lnum
    end)

    return { prev = prev or -1, next = next or -1 }
end

---@param opts { reverse: boolean }
---@return boolean
local function jump_line_within_file(opts)
    local current_filename = vim.api.nvim_buf_get_name(0)
    local current_lnum = vim.api.nvim_win_get_cursor(0)[1]

    local neighbors = get_neighboring_bookmarks(current_filename, current_lnum)
    if not opts.reverse and 0 < neighbors.next then
        index = neighbors.next
        jump_cursor(opts)
        return true
    elseif opts.reverse and 0 < neighbors.prev then
        index = neighbors.prev
        jump_cursor(opts)
        return true
    end
    return false
end

---@param opts { reverse: boolean }
function M.jump(opts)
    local bookmarks = bookmark.get_bookmarks()
    if #bookmarks == 0 then
        return
    end

    local jumped = jump_line_within_file(opts)
    if jumped then
        return
    end

    move_index(opts)
    jump_cursor(opts)
end

function M.reset_index()
    index = 1
end

function M.get_index()
    return index
end

return M
