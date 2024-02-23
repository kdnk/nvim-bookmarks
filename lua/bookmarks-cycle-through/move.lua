local core = require("bookmarks-cycle-through.core")
local bookmark = require("bookmarks-cycle-through.bookmark")
local sync = require("bookmarks-cycle-through.sync")

local M = {}

local index = 1

local function move_cursor(i)
    local bookmarks = bookmark.get_bookmarks()
    local b = bookmarks[i]

    vim.api.nvim_set_current_buf(b.bufnr)
    local win_id = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_cursor(win_id, { b.lnum, 0 })
end

local function increase_index()
    local bookmarks = bookmark.get_bookmarks()
    index = index + 1
    if index > #bookmarks then
        index = 1
    end
end

local function decrease_index()
    local bookmarks = bookmark.get_bookmarks()
    index = index - 1
    if index <= 0 then
        index = #bookmarks
    end
end

---@param filename string
---@param lnum integer
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
local function move_line_within_file(opts)
    local current_filename = vim.api.nvim_buf_get_name(0)
    local current_lnum = vim.api.nvim_win_get_cursor(0)[1]

    local neighbors = get_neighboring_bookmarks(current_filename, current_lnum)
    if not opts.reverse and 0 < neighbors.bigger_index then
        index = neighbors.bigger_index
        move_cursor(index)
        return true
    elseif opts.reverse and 0 < neighbors.smaller_index then
        index = neighbors.smaller_index
        move_cursor(index)
        return true
    end
    return false
end

---@param opts { reverse: boolean }
local function normalize_bookmarks(opts)
    local bookmarks = bookmark.get_bookmarks()
    local b = bookmarks[index]
    local max_lnum = vim.api.nvim_buf_line_count(b.bufnr)
    if max_lnum < b.lnum then
        sync.delete(b.bufnr, b.lnum)
        sync.sync_bookmarks_to_signs()

        if not opts.reverse then
            index = #bookmarks < index and #bookmarks or index
        else
            decrease_index()
        end
    end
end

function M.move_prev()
    normalize_bookmarks({ reverse = true })
    local moved = move_line_within_file({ reverse = true })
    if moved then
        return
    end

    decrease_index()
    move_cursor(index)
end

function M.move_next()
    normalize_bookmarks({ reverse = false })
    local moved = move_line_within_file({ reverse = false })
    if moved then
        return
    end

    increase_index()
    move_cursor(index)
end

function M.reset_index()
    index = 1
end

return M
