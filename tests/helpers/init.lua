-- Test helper utilities

local M = {}

-- Create a temporary test buffer
-- @return number Buffer handle
function M.create_test_buffer()
    local bufnr = vim.api.nvim_create_buf(false, true)
    return bufnr
end

-- Clean up a test buffer
-- @param bufnr number Buffer handle to clean up
function M.cleanup_test_buffer(bufnr)
    if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end
end

-- Create a temporary test file with content
-- @param content string[] Lines of content
-- @return string File path
function M.create_test_file(content)
    local tmpfile = vim.fn.tempname()
    vim.fn.writefile(content or {}, tmpfile)
    return tmpfile
end

-- Get a temporary directory for test data
-- @return string Directory path
function M.get_test_data_dir()
    local tmpdir = vim.fn.tempname()
    vim.fn.mkdir(tmpdir, "p")
    return tmpdir
end

-- Set up test environment before each test
function M.setup_test_env()
    -- Clear any existing bookmarks
    package.loaded["bookmarks.bookmark"] = nil
    package.loaded["bookmarks.extmark"] = nil
    package.loaded["bookmarks.sign"] = nil
    package.loaded["bookmarks.sync"] = nil
    package.loaded["bookmarks.persist"] = nil
    package.loaded["bookmarks.jump"] = nil
    package.loaded["bookmarks.config"] = nil
end

-- Tear down test environment after each test
function M.teardown_test_env()
    -- Cleanup is done in individual tests
end

-- Custom assertion: Check if a bookmark exists
-- @param bufnr number Buffer number
-- @param lnum number Line number
function M.assert_bookmark_exists(bufnr, lnum)
    local bookmark = require("bookmarks.bookmark")
    assert(bookmark.exists(bufnr, lnum), string.format("Expected bookmark at bufnr=%d, lnum=%d", bufnr, lnum))
end

-- Custom assertion: Check if an extmark exists at a specific line
-- @param bufnr number Buffer number
-- @param lnum number Line number
function M.assert_extmark_at(bufnr, lnum)
    local extmark = require("bookmarks.extmark")
    local ns = vim.api.nvim_create_namespace("bookmarks")
    local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, ns, { lnum - 1, 0 }, { lnum - 1, -1 }, {})
    assert(#extmarks > 0, string.format("Expected extmark at bufnr=%d, lnum=%d", bufnr, lnum))
end

-- Custom assertion: Check if a sign exists at a specific line
-- @param bufnr number Buffer number
-- @param lnum number Line number
function M.assert_sign_at(bufnr, lnum)
    local signs = vim.fn.sign_getplaced(bufnr, { lnum = lnum })
    assert(#signs > 0 and #signs[1].signs > 0, string.format("Expected sign at bufnr=%d, lnum=%d", bufnr, lnum))
end

return M
