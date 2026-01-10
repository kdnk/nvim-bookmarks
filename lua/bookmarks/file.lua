local M = {}

---@param filename string
---@return number
function M.get_max_lnum(filename)
    -- Check if buffer is already loaded
    local bufnr = vim.fn.bufnr(filename)
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        return vim.api.nvim_buf_line_count(bufnr)
    end

    local file = io.open(filename, "r")
    if file == nil then
        error("[io.get_max_lnum] file is nil: " .. filename)
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
    local function get_directory_part(path)
        return path:match("(.+)/[^/]*$")
    end

    local function mkdir_p(path)
        if path and #path > 0 then
            local success, err = os.execute('mkdir -p "' .. path .. '"')
            if not success then
                require("bookmarks.notify").warn("Error creating directory: " .. err)
            end
        end
    end

    mkdir_p(get_directory_part(filename))
    vim.fn.writefile(json, filename)
end

return M
