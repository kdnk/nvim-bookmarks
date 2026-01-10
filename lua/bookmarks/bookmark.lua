local file = require("bookmarks.file")

local M = {}

---@class Bookmark
---@field id string
---@field filename string
---@field bufnr integer
---@field lnum number
---@field extmark_id integer|nil

---@type Bookmark[]
local bookmarks = {}

local function generate_id()
    return tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
end

function M.update_bufnr()
    for _, b in ipairs(bookmarks) do
        local bufnr = vim.fn.bufnr(b.filename)
        b.bufnr = bufnr -- will be -1 if not in buffer list
    end
end

---@param bufnr integer
---@param lnum number
---@return Bookmark|nil
function M.find(bufnr, lnum)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    for _, b in ipairs(bookmarks) do
        if b.filename == filename and b.lnum == lnum then
            return b
        end
    end
    return nil
end

---@param bufnr integer
---@param lnum number
---@return boolean
function M.exists(bufnr, lnum)
    return M.find(bufnr, lnum) ~= nil
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

---@param filename string
---@param lnum number
---@param extmark_id integer
function M.update_extmark_id(filename, lnum, extmark_id)
    for _, b in ipairs(bookmarks) do
        if b.filename == filename and b.lnum == lnum then
            b.extmark_id = extmark_id
        end
    end
end

function M.add(bufnr, lnum)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    table.insert(bookmarks, {
        id = generate_id(),
        filename = filename,
        bufnr = bufnr,
        lnum = lnum,
    })

    vim.api.nvim_exec_autocmds("User", { pattern = "BookmarkAdded" })
end

---@param id string
function M.delete_by_id(id)
    for i, b in ipairs(bookmarks) do
        if b.id == id then
            table.remove(bookmarks, i)
            vim.api.nvim_exec_autocmds("User", { pattern = "BookmarkDeleted" })
            return
        end
    end
end

---@param bufnr integer
---@param lnum number
---@return nil
function M.delete(bufnr, lnum)
    local b = M.find(bufnr, lnum)
    if b then
        M.delete_by_id(b.id)
    end
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

    local valid_bs = vim.tbl_filter(is_valid, bs)
    for _, b in ipairs(valid_bs) do
        if not b.id then
            b.id = generate_id()
        end
    end
    return valid_bs
end

return M
