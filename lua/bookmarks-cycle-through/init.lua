local bookmark = require("bookmarks-cycle-through.bookmark")
local sign = require("bookmarks-cycle-through.sign")
local move = require("bookmarks-cycle-through.move")

local M = {}

local list_map = function(list, map)
    local new_list = {}
    for index, value in ipairs(list) do
        table.insert(new_list, map(value, index))
    end
    return new_list
end

local list_find_index = function(list, target)
    for index, value in ipairs(list) do
        if target == value then
            return index
        end
    end
    return nil
end

local int_lines = function(file)
    local lines = list_map(vim.fn["bm#all_lines"](file), function(line)
        return tonumber(line)
    end)
    table.sort(lines)
    return lines
end

local get_file_index = function(file)
    return list_find_index(vim.fn["bm#all_files"](), file)
end

local get_line_index = function(file, line)
    local lines = int_lines(file)
    table.sort(lines)
    lines = int_lines(file)
    return list_find_index(lines, line)
end

local get_last_line_index = function(file_index)
    local file = vim.fn["bm#all_files"]()[file_index]
    return #int_lines(file)
end

local goto_file_line = function(file, line)
    local bufnr = vim.fn.bufnr(file, true)
    vim.api.nvim_set_current_buf(bufnr)

    local win_id = vim.api.nvim_get_current_win()

    vim.api.nvim_win_set_cursor(win_id, { line, 0 })
end

function M.bookmark_count_or_index()
    local bookmarks = {}
    for _, file in ipairs(vim.fn["bm#all_files"]()) do
        local lines = int_lines(file)
        table.sort(lines)
        for _, line in ipairs(lines) do
            table.insert(bookmarks, file .. ":" .. line)
        end
    end

    if (not M.latest_file_index) or not M.latest_line_index then
        return #bookmarks
    end

    local current_file = vim.fn["bm#all_files"]()[M.latest_file_index]

    local lines = int_lines(current_file)
    table.sort(lines)

    if M.latest_line_index > #lines then
        return #bookmarks
    end

    if #lines == 0 then
        return #bookmarks
    end

    local current_line = lines[M.latest_line_index]
    local current_bookmark = current_file .. ":" .. current_line
    local current_bookmark_index = list_find_index(bookmarks, current_bookmark)
    return current_bookmark_index .. "/" .. #bookmarks
end

function M.bookmark_toggle()
    if not M.latest_file_index then
        M.latest_file_index = list_find_index(vim.fn["bm#all_files"](), vim.api.nvim_buf_get_name(0))
        M.latest_line_index = vim.api.nvim_win_get_cursor(0)[1]
    end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Plug>BookmarkToggle", true, true, true), "n", true)
end

function M.cycle_through(opts)
    local reverse = opts.reverse
    local max_file_count = #vim.fn["bm#all_files"]()

    if max_file_count == 0 then
        -- no bookmarks
        return
    end

    -- inner file
    local current_file = vim.api.nvim_buf_get_name(0)
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    if list_find_index(vim.fn["bm#all_files"](), current_file) ~= nil then
        local lines = int_lines(current_file)
        if reverse then
            table.sort(lines, function(a, b)
                return a > b
            end)
        end
        for _, line in ipairs(lines) do
            if not reverse then
                if current_line < line then
                    M.latest_file_index = get_file_index(current_file)
                    M.latest_line_index = get_line_index(current_file, line)

                    goto_file_line(current_file, line)
                    return
                end
            else
                if current_line > line then
                    M.latest_file_index = get_file_index(current_file)
                    M.latest_line_index = get_line_index(current_file, line)
                    goto_file_line(current_file, line)
                    return
                end
            end
        end
        M.latest_file_index = get_file_index(current_file)
        M.latest_line_index = lines[#lines]
    end

    -- outer file
    if M.latest_file_index == nil then
        M.latest_file_index = 1
    end

    if M.latest_line_index == nil then
        M.latest_line_index = 1
    end

    if not reverse then
        if max_file_count <= M.latest_file_index then
            M.latest_file_index = 1
            M.latest_line_index = 1
        else
            M.latest_file_index = M.latest_file_index + 1
            M.latest_line_index = 1
        end
    else
        if M.latest_file_index == 1 then
            M.latest_file_index = max_file_count
            M.latest_line_index = get_last_line_index(M.latest_file_index)
        else
            M.latest_file_index = M.latest_file_index - 1
            M.latest_line_index = get_last_line_index(M.latest_file_index)
        end
    end

    local next_file = vim.fn["bm#all_files"]()[M.latest_file_index]
    local lines = int_lines(next_file)
    local next_line = lines[M.latest_line_index]
    goto_file_line(next_file, next_line)
end

function M.reset()
    bookmark.remove_all_bookmarks()
    move.reset_index()
    sign.remove_all_signs()
end

function M.toggle()
    sign.toggle()
end

return M
