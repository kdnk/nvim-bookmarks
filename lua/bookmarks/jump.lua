local bookmark = require("bookmarks.bookmark")

local M = {}

---@param opts { reverse: boolean }
function M.jump(opts)
    local bs = bookmark.list()
    if #bs == 0 then
        return
    end

    local curr_file = vim.api.nvim_buf_get_name(0)
    local curr_lnum = vim.api.nvim_win_get_cursor(0)[1]

    local target_index = -1

    if not opts.reverse then
        -- Forward: find first bookmark after current position
        for i, b in ipairs(bs) do
            if b.filename > curr_file or (b.filename == curr_file and b.lnum > curr_lnum) then
                target_index = i
                break
            end
        end
        -- Wrap around to the first bookmark if none found after current position
        if target_index == -1 then
            target_index = 1
        end
    else
        -- Backward: find first bookmark before current position
        for i = #bs, 1, -1 do
            local b = bs[i]
            if b.filename < curr_file or (b.filename == curr_file and b.lnum < curr_lnum) then
                target_index = i
                break
            end
        end
        -- Wrap around to the last bookmark if none found before current position
        if target_index == -1 then
            target_index = #bs
        end
    end

    local b = bs[target_index]
    if b then
        local bufnr = b.bufnr
        if not vim.api.nvim_buf_is_valid(bufnr) then
            bufnr = vim.fn.bufadd(b.filename)
            vim.fn.bufload(bufnr)
            b.bufnr = bufnr
        end

        local line_count = vim.api.nvim_buf_line_count(bufnr)
        if b.lnum > line_count then
            bookmark.delete(bufnr, b.lnum)
            vim.notify(
                "Bookmark at line " .. b.lnum .. " removed because the line was deleted.",
                vim.log.levels.WARN
            )
            return
        end

        vim.api.nvim_set_current_buf(bufnr)
        local win_id = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_cursor(win_id, { b.lnum, 0 })
    end
end

-- These are kept for backward compatibility with init.lua and tests
function M.reset_index() end
function M.get_index() return 1 end

return M