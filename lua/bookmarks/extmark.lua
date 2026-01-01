local config = require("bookmarks.config")

local M = {}

-- namespace for extmarks
local ns_id = vim.api.nvim_create_namespace("bookmarks")

---@class ExtmarkInfo
---@field bufnr integer
---@field lnum number
---@field extmark_id integer

-- extmark管理用のテーブル bufnr -> { lnum -> extmark_id }
---@type table<integer, table<integer, integer>>
local extmarks = {}

---@param bufnr integer
---@param lnum number
---@return integer|nil
function M.get_extmark_id(bufnr, lnum)
    if not extmarks[bufnr] then
        return nil
    end
    return extmarks[bufnr][lnum]
end

---@param bufnr integer
---@param lnum number
---@return integer extmark_id
function M.add(bufnr, lnum)
    if not extmarks[bufnr] then
        extmarks[bufnr] = {}
    end

    -- 既存のextmarkがある場合は削除
    local existing_id = extmarks[bufnr][lnum]
    if existing_id then
        pcall(vim.api.nvim_buf_del_extmark, bufnr, ns_id, existing_id)
    end

    -- 新しいextmarkを作成 (0-indexed行番号)
    -- signは別途sign.luaで管理するため、ここでは作成しない
    local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, ns_id, lnum - 1, 0, {})

    extmarks[bufnr][lnum] = extmark_id
    return extmark_id
end

---@param bufnr integer
---@param lnum number
function M.delete(bufnr, lnum)
    if not extmarks[bufnr] or not extmarks[bufnr][lnum] then
        return
    end

    local extmark_id = extmarks[bufnr][lnum]
    pcall(vim.api.nvim_buf_del_extmark, bufnr, ns_id, extmark_id)
    extmarks[bufnr][lnum] = nil
end

---@param bufnr integer
function M.clear_buffer(bufnr)
    if not extmarks[bufnr] then
        return
    end

    for lnum, extmark_id in pairs(extmarks[bufnr]) do
        pcall(vim.api.nvim_buf_del_extmark, bufnr, ns_id, extmark_id)
    end
    extmarks[bufnr] = nil
end

function M.clear_all()
    for bufnr, _ in pairs(extmarks) do
        M.clear_buffer(bufnr)
    end
    extmarks = {}
end

---@param bufnr integer
---@return table<integer, integer> -- lnum -> new_lnum のマッピング
function M.get_position_changes(bufnr)
    local changes = {}
    if not extmarks[bufnr] then
        return changes
    end

    for old_lnum, extmark_id in pairs(extmarks[bufnr]) do
        local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_id, extmark_id, {})
        if mark and #mark > 0 then
            local new_lnum = mark[1] + 1 -- 1-indexedに変換
            if old_lnum ~= new_lnum then
                changes[old_lnum] = new_lnum
            end
        end
    end

    return changes
end

---@param bufnr integer
---@param old_lnum number
---@param new_lnum number
function M.update_lnum(bufnr, old_lnum, new_lnum)
    if not extmarks[bufnr] or not extmarks[bufnr][old_lnum] then
        return
    end

    local extmark_id = extmarks[bufnr][old_lnum]
    extmarks[bufnr][old_lnum] = nil
    extmarks[bufnr][new_lnum] = extmark_id
end

return M
