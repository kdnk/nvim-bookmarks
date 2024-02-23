local core = require("bookmarks.core")

local M = {}

---@param bufnr integer
---@param lnum number
---@return boolean
function M.has_signs(bufnr, lnum)
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
function M.add_sign(bufnr, lnum)
    local sign_id = 0
    vim.fn.sign_place(sign_id, vim.g.bookmark_sign_group, vim.g.bookmark_sign_name, bufnr, { lnum = lnum })
end

---@param bufnr integer
---@param lnum integer
function M.delete_sign(bufnr, lnum)
    local signs = get_signs(bufnr, lnum)
    core.list.each(signs, function(sign)
        vim.fn.sign_unplace(vim.g.bookmark_sign_group, { buffer = bufnr, id = sign.id })
    end)
end

function M.remove_all_signs()
    vim.fn.sign_unplace(vim.g.bookmark_sign_group)
end

return M
