local file = require("bookmarks.file")

local M = {}

---@class Bookmark
---@field filename string
---@field bufnr integer
---@field lnum number

---@type Bookmark[]
local bookmarks = {}

function M.update_bufnr()
    for _, b in ipairs(bookmarks) do
        local bufnr = vim.fn.bufadd(b.filename)
        b.bufnr = bufnr
    end
end

---@param bufnr integer
---@param lnum number
---@return boolean
function M.exists(bufnr, lnum)
    for _, b in ipairs(bookmarks) do
        if b.bufnr == bufnr and b.lnum == lnum then
            return true
        end
    end
    return false
end

---@param b Bookmark
---@return boolean
local function is_valid(b)
    if not b then
        return false
    end
    local success, max_lnum = pcall(file.get_max_lnum, b.filename)
    return success and b.lnum <= max_lnum
end

---@param index integer
---@param update_index fun(): integer
---@return integer
function M.sanitize(index, update_index)
    local bs = M.list()
    if is_valid(bs[index]) then
        return index
    end

    local b = bs[index]
    if b ~= nil then
        M.delete(b.bufnr, b.lnum)
    end

    index = update_index()
    bs = M.list()

    if is_valid(bs[index]) then
        return index
    elseif b then
        return M.sanitize(index, update_index)
    else
        -- noop
        return -1
    end
end

---@return Bookmark[]
function M.list()
    M.update_bufnr()

    -- Get unique filenames and group bookmarks by filename
    local grouped = {}
    local filenames = {}
    for _, b in ipairs(bookmarks) do
        if not grouped[b.filename] then
            grouped[b.filename] = {}
            table.insert(filenames, b.filename)
        end
        table.insert(grouped[b.filename], b)
    end

    local new_bookmarks = {}
    table.sort(filenames)
    for _, filename in ipairs(filenames) do
        local bs = grouped[filename]
        table.sort(bs, function(a, b)
            return a.lnum < b.lnum
        end)
        for _, b in ipairs(bs) do
            table.insert(new_bookmarks, b)
        end
    end

    return new_bookmarks
end

function M.update_all(bs)
    bookmarks = bs
end

---@param bufnr integer
---@param lnum number
---@return nil
function M.add(bufnr, lnum)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    table.insert(bookmarks, { filename = filename, bufnr = bufnr, lnum = lnum })

    vim.api.nvim_exec_autocmds("User", { pattern = "BookmarkAdded" })
end

---@param bufnr integer
---@param lnum number
---@return nil
function M.delete(bufnr, lnum)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    for i = #bookmarks, 1, -1 do
        local b = bookmarks[i]
        if b.filename == filename and b.lnum == lnum then
            table.remove(bookmarks, i)
        end
    end

    vim.api.nvim_exec_autocmds("User", { pattern = "BookmarkDeleted" })
end

function M.remove_all()
    bookmarks = {}
end

function M.to_json()
    local valid_bookmarks = vim.tbl_filter(is_valid, M.list())
    return { vim.json.encode(valid_bookmarks) }
end

---@param json any[]
---@return Bookmark[]
function M.from_json(json)
    if not json or not json[1] then
        return {}
    end

    local success, bs = pcall(vim.json.decode, json[1])
    if not success or not bs then
        return {}
    end

    return vim.tbl_filter(is_valid, bs)
end

return M
