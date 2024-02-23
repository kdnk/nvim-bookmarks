local M = {}

local core = require("bookmarks-cycle-through.core")

local function has_signs(bufnr, lnum)
    local signs = vim.fn.sign_getplaced(bufnr, { group = vim.g.bookmark_sign_group, lnum = lnum })[1]["signs"]

    return core.list.includes(signs, function(sign)
        return sign.lnum == lnum
    end)
end

local function get_signs(bufnr, lnum)
    local signs = vim.fn.sign_getplaced(bufnr, { group = vim.g.bookmark_sign_group, lnum = lnum })[1]["signs"]

    return core.list.filter(signs, function(sign)
        return sign.lnum == lnum
    end)
end

function M.toggle()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local bufnr = vim.api.nvim_get_current_buf()
    local sign_id = 0

    if has_signs(bufnr, lnum) then
        local signs = get_signs(bufnr, lnum)
        core.list.each(signs, function(sign)
            vim.fn.sign_unplace(vim.g.bookmark_sign_group, { buffer = bufnr, id = sign.id })
        end)
    else
        vim.fn.sign_place(sign_id, vim.g.bookmark_sign_group, vim.g.bookmark_sign_name, bufnr, { lnum = lnum })
    end
end

return M
