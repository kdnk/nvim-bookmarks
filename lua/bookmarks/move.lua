local core = require("bookmarks.core")
local bookmark = require("bookmarks.bookmark")
local sync = require("bookmarks.sync")

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

---@param opts { reverse: boolean }
---@return integer
local function normalize_bookmark(opts)
    local bookmarks = bookmark.get_bookmarks()
    local b = bookmarks[index]

    local max_lnum = vim.api.nvim_buf_line_count(b.bufnr)
    if max_lnum < b.lnum then
        sync.delete(b.bufnr, b.lnum)
        sync.sync_bookmarks_to_signs()

        bookmarks = bookmark.get_bookmarks()
        if not opts.reverse then
            index = #bookmarks < index and #bookmarks or index
            return index
        else
            return move_index(opts)
        end
    else
        return index
    end
end

---@param i integer
---@param opts { reverse: boolean }
---@return nil
local function move_cursor(i, opts)
    i = normalize_bookmark(opts)
    local bookmarks = bookmark.get_bookmarks()
    local b = bookmarks[i]
    vim.api.nvim_set_current_buf(b.bufnr)
    local win_id = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_cursor(win_id, { b.lnum, 0 })
end

---@param filename string
---@param lnum integer
---@return { smaller_index: integer, bigger_index: integer }
local function get_neighboring_bookmarks(filename, lnum)
    local bookmarks = bookmark.get_bookmarks()

    local smaller_index = core.list.find_last_index(bookmarks, function(b)
        return filename == b.filename and b.lnum < lnum
    end)
    local bigger_index = core.list.find_index(bookmarks, function(b)
        return b.filename == filename and lnum < b.lnum
    end)

    return { smaller_index = smaller_index or -1, bigger_index = bigger_index or -1 }
end

---@param opts { reverse: boolean }
---@return boolean
local function move_line_within_file(opts)
    local current_filename = vim.api.nvim_buf_get_name(0)
    local current_lnum = vim.api.nvim_win_get_cursor(0)[1]

    local neighbors = get_neighboring_bookmarks(current_filename, current_lnum)
    if not opts.reverse and 0 < neighbors.bigger_index then
        index = neighbors.bigger_index
        move_cursor(index, opts)
        return true
    elseif opts.reverse and 0 < neighbors.smaller_index then
        index = neighbors.smaller_index
        move_cursor(index, opts)
        return true
    end
    return false
end

function M.move_prev()
    local bookmarks = bookmark.get_bookmarks()
    if #bookmarks == 0 then
        return
    end

    local opts = { reverse = true }
    local moved = move_line_within_file(opts)
    if moved then
        return
    end

    move_index(opts)
    move_cursor(index, opts)
end

function M.move_next()
    local bookmarks = bookmark.get_bookmarks()
    if #bookmarks == 0 then
        return
    end

    local opts = { reverse = false }
    local moved = move_line_within_file(opts)
    if moved then
        return
    end

    move_index(opts)
    move_cursor(index, opts)
end

function M.reset_index()
    index = 1
end

function M.get_index()
    return index
end

return M
