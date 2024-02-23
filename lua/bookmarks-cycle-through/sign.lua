local core = require("bookmarks-cycle-through.core")
local bookmark = require("bookmarks-cycle-through.bookmark")

local M = {}

---@param bufnr integer
---@param lnum number
---@return boolean
local function has_signs(bufnr, lnum)
    local signs = vim.fn.sign_getplaced(bufnr, { group = vim.g.bookmark_sign_group, lnum = lnum })[1]["signs"]

    return core.list.includes(signs, function(sign)
        return sign.lnum == lnum
    end)
end

---@param bufnr integer
---@param lnum number
---@return Sign[]
local function get_signs(bufnr, lnum)
    local signs = vim.fn.sign_getplaced(bufnr, { group = vim.g.bookmark_sign_group, lnum = lnum })[1]["signs"] --[[@as Sign]]

    return core.list.filter(signs, function(sign)
        return sign.lnum == lnum
    end)
end

---@param bufnr integer
---@param lnum number
local function add_sign(bufnr, lnum)
    local sign_id = 0
    vim.fn.sign_place(sign_id, vim.g.bookmark_sign_group, vim.g.bookmark_sign_name, bufnr, { lnum = lnum })
end

---@param bufnr integer
---@param sign_id integer
local function delete_sign(bufnr, sign_id)
    vim.fn.sign_unplace(vim.g.bookmark_sign_group, { buffer = bufnr, id = sign_id })
end

function M.toggle()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local bufnr = vim.api.nvim_get_current_buf()

    if has_signs(bufnr, lnum) then
        local signs = get_signs(bufnr, lnum)
        core.list.each(signs, function(sign)
            delete_sign(bufnr, sign.id)
            bookmark.delete_bookmark(bufnr, lnum)
        end)
    else
        add_sign(bufnr, lnum)
        bookmark.add_bookmark(bufnr, lnum)
    end
end

return M
