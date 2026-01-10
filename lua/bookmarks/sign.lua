local config = require("bookmarks.config")

local M = {}

---@class Sign
---@diagnostic disable-next-line: duplicate-doc-field
---@field group string
---@diagnostic disable-next-line: duplicate-doc-field
---@field id integer
---@diagnostic disable-next-line: duplicate-doc-field
---@field lnum number
---@diagnostic disable-next-line: duplicate-doc-field
---@field bufnr integer
---@diagnostic disable-next-line: duplicate-doc-field
---@field name string
---@diagnostic disable-next-line: duplicate-doc-field
---@field priority number

---@param bufnr integer
---@param lnum number
---@return Sign[]
local function get_signs(bufnr, lnum)
    local signs = vim.fn.sign_getplaced(bufnr, { group = config.sign.group, lnum = lnum })[1]["signs"] --[[@as Sign]]

    return vim.tbl_filter(function(sign)
        return sign.lnum == lnum
    end, signs)
end

---@param bufnr integer
---@param lnum number
function M.add(bufnr, lnum)
    local sign_id = 0
    vim.fn.sign_place(sign_id, config.sign.group, config.sign.name, bufnr, { lnum = lnum, priority = 1000 })
end

---@param bufnr integer
---@param lnum integer
function M.delete(bufnr, lnum)
    local signs = get_signs(bufnr, lnum)
    for _, sign in ipairs(signs) do
        vim.fn.sign_unplace(config.sign.group, { buffer = bufnr, id = sign.id })
    end
end

function M.remove_all()
    vim.fn.sign_unplace(config.sign.group)
end

return M
