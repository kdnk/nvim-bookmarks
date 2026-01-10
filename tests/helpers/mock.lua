-- Mock utilities for Neovim APIs using luassert

local stub = require("luassert.stub")
local mock = require("luassert.mock")

local M = {}

-- Store stubs for cleanup
M._stubs = {}

-- Mock buffer name mapping
M._buf_names = {}

-- Set up vim API mocks using luassert stubs
function M.setup_vim_api()
    M._buf_names = {}

    -- Stub nvim_buf_get_name
    M._stubs.nvim_buf_get_name = stub(vim.api, "nvim_buf_get_name")
    M._stubs.nvim_buf_get_name.invokes(function(bufnr)
        if bufnr == 0 then
            -- Try to get current bufnr if nvim_get_current_buf is available
            local success, current = pcall(vim.api.nvim_get_current_buf)
            if success then
                bufnr = current
            end
        end
        return M._buf_names[bufnr] or ("/test/file_" .. bufnr .. ".lua")
    end)

    -- Stub vim.fn.bufnr (reverse lookup)
    M._stubs.bufnr = stub(vim.fn, "bufnr")
    M._stubs.bufnr.invokes(function(name)
        if name == "%" then
             local success, current = pcall(vim.api.nvim_get_current_buf)
             return success and current or -1
        end
        for bufnr, filename in pairs(M._buf_names) do
            if filename == name then
                return bufnr
            end
        end
        -- Default mock behavior for unmapped files if strictly needed, 
        -- but returning -1 is safer for "not found"
        return -1 
    end)

    -- Stub vim.fn.bufload
    M._stubs.bufload = stub(vim.fn, "bufload")
end

-- Set the return value for nvim_buf_get_name
-- @param bufnr number Buffer number
-- @param filename string Filename to return
function M.set_buf_name(bufnr, filename)
    M._buf_names[bufnr] = filename
end

-- File mock state
M._files = {}
M._file_contents = {}
M._written_files = {}

-- Mock file I/O functions using luassert stubs
function M.setup_file_io()
    M._files = {}
    M._file_contents = {}
    M._written_files = {}

    -- Stub fs_stat
    M._stubs.fs_stat = stub(vim.loop, "fs_stat")
    M._stubs.fs_stat.invokes(function(path)
        if M._files[path] then
            return { type = "file" }
        end
        return nil
    end)

    -- Stub readfile
    M._stubs.readfile = stub(vim.fn, "readfile")
    M._stubs.readfile.invokes(function(path)
        return M._file_contents[path] or {}
    end)

    -- Stub writefile
    M._stubs.writefile = stub(vim.fn, "writefile")
    M._stubs.writefile.invokes(function(lines, path)
        M._written_files[path] = lines
        M._files[path] = true
    end)
end

-- Set file existence
-- @param path string File path
-- @param exists boolean Whether file exists
function M.set_file_exists(path, exists)
    if exists then
        M._files[path] = true
    else
        M._files[path] = nil
    end
end

-- Set file contents for readfile mock
-- @param path string File path
-- @param contents string[] File contents as lines
function M.set_file_contents(path, contents)
    M._file_contents[path] = contents
    M.set_file_exists(path, true)
end

-- Get written file contents
-- @param path string File path
-- @return string[]|nil File contents
function M.get_written_file(path)
    return M._written_files[path]
end

-- Git mock state
M._git_branch = "main"

-- Mock git operations using luassert stubs
function M.setup_git()
    M._git_branch = "main"

    -- Stub systemlist for git commands
    M._stubs.systemlist = stub(vim.fn, "systemlist")
    M._stubs.systemlist.invokes(function(cmd)
        if type(cmd) == "string" and cmd:match("git branch") then
            return { M._git_branch }
        end
        -- For other commands, return empty table
        return {}
    end)
end

-- Set git branch name
-- @param branch string Branch name
function M.set_git_branch(branch)
    M._git_branch = branch
end

-- Tear down all mocks and restore original functions
function M.teardown()
    -- Revert all stubs using luassert
    for name, s in pairs(M._stubs) do
        s:revert()
    end

    -- Clear stub references
    M._stubs = {}

    -- Clear mock state
    M._buf_names = {}
    M._files = {}
    M._file_contents = {}
    M._written_files = {}
    M._git_branch = "main"
end

-- Reset mocks without tearing down (keeps mocks active but clears state)
function M.reset()
    M._buf_names = {}
    M._files = {}
    M._file_contents = {}
    M._written_files = {}
    M._git_branch = "main"
end

function M.clear_written_files()
    M._written_files = {}
end

return M
