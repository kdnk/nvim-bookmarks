local M = {}

---@param filename string
---@return number
function M.get_max_lnum(filename)
    local file = io.open(filename, "r")
    if file == nil then
        error("[io.get_max_lnum] file is nil")
    end
    local line_count = 0
    for _ in file:lines() do
        line_count = line_count + 1
    end
    file:close()
    return line_count
end

function M.exists(filename)
    return vim.loop.fs_stat(filename) and true or false
end

function M.json_read(filename)
    local json = vim.fn.readfile(filename)
    return json
end

function M.json_write(json, filename)
    vim.fn.writefile(json, filename)
end

return M
