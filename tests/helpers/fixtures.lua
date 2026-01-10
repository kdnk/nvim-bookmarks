-- Test data generators and fixtures

local M = {}

-- Generate a single bookmark object
-- @param bufnr number Buffer number
-- @param lnum number Line number
-- @param filename string|nil Optional filename (defaults to test filename)
-- @return table Bookmark object
function M.generate_bookmark(bufnr, lnum, filename)
    return {
        filename = filename or ("/test/file_" .. bufnr .. ".lua"),
        bufnr = bufnr,
        lnum = lnum,
    }
end

-- Generate multiple bookmark objects
-- @param count number Number of bookmarks to generate
-- @return table[] Array of bookmark objects
function M.generate_bookmarks(count)
    local bookmarks = {}
    for i = 1, count do
        table.insert(bookmarks, M.generate_bookmark(i, i * 10))
    end
    return bookmarks
end

-- Generate test file content
-- @param lines number Number of lines
-- @return string[] Array of lines
function M.generate_test_file_content(lines)
    local content = {}
    for i = 1, lines do
        table.insert(content, string.format("Line %d: test content", i))
    end
    return content
end

-- Generate sample JSON backup data
-- @return string JSON string
function M.sample_json_backup()
    return vim.fn.json_encode({
        M.generate_bookmark(1, 10, "/test/file1.lua"),
        M.generate_bookmark(1, 20, "/test/file1.lua"),
        M.generate_bookmark(2, 15, "/test/file2.lua"),
    })
end

-- Generate invalid JSON for error testing
-- @return string Invalid JSON string
function M.invalid_json_backup()
    return '{"invalid": json'
end

-- Generate bookmarks for different files
-- @return table[] Array of bookmark objects from different files
function M.generate_multi_file_bookmarks()
    return {
        M.generate_bookmark(1, 30, "/test/file1.lua"),
        M.generate_bookmark(1, 20, "/test/file1.lua"),
        M.generate_bookmark(1, 10, "/test/file1.lua"),
        M.generate_bookmark(2, 25, "/test/file2.lua"),
        M.generate_bookmark(2, 15, "/test/file2.lua"),
        M.generate_bookmark(3, 50, "/test/file3.lua"),
    }
end

-- Generate test configuration
-- @return table Configuration object
function M.generate_test_config()
    return {
        persist = {
            enable = true,
            per_branch = true,
        },
        scrollbar = {
            enable = false,
            text = "⚑",
        },
        sign = {
            group = "Bookmark",
            name = "Bookmark",
            text = "⚑",
        },
    }
end

return M
