local core = require("bookmarks.core")
local config = require("bookmarks.config")

local M = {}

---@class Sign
---@field group string
---@field id integer
---@field lnum number
---@field bufnr integer
---@field name string
---@field priority number

---@param bufnr integer
---@param lnum number
---@return boolean
function M.has_signs(bufnr, lnum)
    local signs = vim.fn.sign_getplaced(bufnr, { group = config.sign.group, lnum = lnum })[1]["signs"]

    return core.list.includes(signs, function(sign)
        return sign.lnum == lnum
    end)
end

---@param bufnr integer
---@param lnum number
---@return Sign[]
local function get_signs(bufnr, lnum)
    local signs = vim.fn.sign_getplaced(bufnr, { group = config.sign.group, lnum = lnum })[1]["signs"] --[[@as Sign]]

    return core.list.filter(signs, function(sign)
        return sign.lnum == lnum
    end)
end

---@param bufnr integer
---@param lnum number
function M.add(bufnr, lnum)
    local sign_id = 0
    vim.fn.sign_place(sign_id, config.sign.group, config.sign.name, bufnr, { lnum = lnum })
end

---@param bufnr integer
---@param lnum integer
function M.delete(bufnr, lnum)
    local signs = get_signs(bufnr, lnum)
    core.list.each(signs, function(sign)
        vim.fn.sign_unplace(config.sign.group, { buffer = bufnr, id = sign.id })
    end)
end

function M.remove_all()
    vim.fn.sign_unplace(config.sign.group)
end

return M
