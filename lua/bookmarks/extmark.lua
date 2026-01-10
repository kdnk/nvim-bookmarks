local M = {}

-- namespace for extmarks
local ns_id = vim.api.nvim_create_namespace("bookmarks")

---@param bufnr integer
---@param lnum number
---@return integer extmark_id
function M.add(bufnr, lnum)
    -- 既存のその行のextmarkを探して消すロジックは、重複を許容するか、呼び出し側で制御する。
    -- 0-indexed行番号
    local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, ns_id, lnum - 1, 0, {})
    return extmark_id
end

---@param bufnr integer
---@param id integer
function M.delete(bufnr, id)
    pcall(vim.api.nvim_buf_del_extmark, bufnr, ns_id, id)
end

---@param bufnr integer
function M.clear_all(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
end

function M.clear_all_buffers()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(bufnr) then
            M.clear_all(bufnr)
        end
    end
end

---@param bufnr integer
---@param id integer
---@return number|nil lnum (1-indexed)
function M.get_lnum(bufnr, id)
    local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_id, id, {})
    if mark and #mark > 0 then
        return mark[1] + 1
    end
    return nil
end

return M
