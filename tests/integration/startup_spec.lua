-- Integration tests for startup and persistence

local mock = require("tests.helpers.mock")
local stub = require("luassert.stub")

describe("startup and persistence (integration)", function()
    local bm
    local bookmark
    local persist
    local config

    local test_data_dir = "/tmp/test_data"
    local test_cwd
    local test_hash_full
    local test_hash
    local expected_path

    before_each(function()
        -- WORKAROUND: Ensure package.path includes project lua directory
        -- It seems minimal_init.lua's path modification is not persisting or not sufficient in this environment
        local cwd = vim.fn.getcwd()
        if not string.find(package.path, cwd .. "/lua/%%?.lua") then
            package.path = package.path .. ";" .. cwd .. "/lua/?.lua;" .. cwd .. "/lua/?/init.lua"
        end

        test_cwd = vim.fn.getcwd()
        test_hash_full = vim.fn.sha256(test_cwd)
        test_hash = test_hash_full:sub(1, 16)
        expected_path = test_data_dir .. "/nvim-bookmarks/" .. test_hash .. "/main.json"

        -- Reset modules
        package.loaded["bookmarks.init"] = nil
        package.loaded["bookmarks.bookmark"] = nil
        package.loaded["bookmarks.persist"] = nil
        package.loaded["bookmarks.config"] = nil
        package.loaded["bookmarks.sign"] = nil
        package.loaded["bookmarks.extmark"] = nil
        package.loaded["bookmarks.sync"] = nil
        package.loaded["bookmarks.file"] = nil
        package.loaded["bookmarks.core"] = nil
        package.loaded["bookmarks.autocmd"] = nil

        -- Setup standard mocks
        mock.setup_vim_api()
        mock.setup_file_io()
        mock.setup_git()

        -- Stub environment-specific functions for path generation
        stub(vim.fn, "stdpath").returns(test_data_dir)
        -- stub(vim.fn, "getcwd") -- Do not stub getcwd
        stub(vim.fn, "sha256").returns(test_hash_full) -- Still stub sha256 to match our pre-calced hash if needed, OR just let it run real sha256.
        -- Actually, if we use real CWD, we don't strictly need to stub sha256 if we use real sha256.
        -- But persist.lua calls vim.fn.sha256.
        -- Let's stub sha256 to be safe/consistent or just let it be.
        -- The test above calculated `test_hash_full` using real `vim.fn.sha256`.
        -- So we don't need to stub sha256 if `persist.lua` calls the real one.
        -- BUT mock.lua might not be stubbing sha256 by default?
        -- mock.lua does NOT stub sha256.
        -- So we can remove stub(vim.fn, "sha256") as well.

        stub(vim.fn, "mkdir") -- Mock mkdir to avoid errors

        -- Stub sign/extmark functions
        stub(vim.fn, "sign_place")
        stub(vim.fn, "sign_define")
        stub(vim.fn, "sign_getplaced").returns({ { signs = {} } })
        stub(vim.api, "nvim_create_namespace").returns(1)
        stub(vim.api, "nvim_buf_set_extmark")
        stub(vim.api, "nvim_buf_get_extmarks").returns({})

        -- Mock file module
        local file = require("bookmarks.file")
        file.get_max_lnum = function(filename)
            return 1000
        end

        -- Load modules
        config = require("bookmarks.config")
        bm = require("bookmarks.init")
        bookmark = require("bookmarks.bookmark")
        persist = require("bookmarks.persist")
    end)

    after_each(function()
        mock.teardown()
    end)

    describe("persistence", function()
        it("should save bookmarks to correct file path", function()
            config.setup()

            local bufnr = 1
            mock.set_buf_name(bufnr, "/test/project/file1.lua")

            -- Add a bookmark
            bookmark.add(bufnr, 10)

            -- Trigger backup
            persist.backup()

            -- Verify writefile was called with correct path and content
            local written = mock.get_written_file(expected_path)
            assert.is_not_nil(written)

            -- Verify content is valid JSON and contains the bookmark
            local json_str = written[1]
            local decoded = vim.json.decode(json_str)
            assert.are.equal(1, #decoded)
            assert.are.equal("/test/project/file1.lua", decoded[1].filename)
            assert.are.equal(10, decoded[1].lnum)
        end)

        it("should not save if persistence is disabled", function()
            config.setup({
                persist = { enable = false },
            })

            local bufnr = 1
            mock.set_buf_name(bufnr, "/test/file1.lua")
            bookmark.add(bufnr, 10)

            persist.backup()

            local written = mock.get_written_file(expected_path)
            assert.is_nil(written)
        end)
    end)

    describe("startup (restore)", function()
        it("should restore bookmarks from file", function()
            -- Prepare mocked file content
            local saved_bookmarks = {
                { filename = "/test/project/file1.lua", bufnr = 1, lnum = 10 },
                { filename = "/test/project/file2.lua", bufnr = 2, lnum = 20 },
            }
            local json_str = vim.json.encode(saved_bookmarks)
            mock.set_file_contents(expected_path, { json_str })

            -- Set up buffer names for resolution
            mock.set_buf_name(1, "/test/project/file1.lua")
            mock.set_buf_name(2, "/test/project/file2.lua")

            -- Initialize plugin
            config.setup()

            -- Manually trigger restore (normally called by setup, but we want to be sure)
            -- Wait, bm.setup() calls config.setup(), but does it call restore?
            -- Let's check init.lua. Assuming it might not, or we want to test persist.restore directly first.
            -- Actually, let's call bm.setup() if it does. If not, we use persist.restore().

            -- Checking init.lua would be good, but assuming persist.restore() is the key.
            persist.restore()

            -- Verify bookmarks are loaded
            -- Note: We need to mock bufadd to return bufnrs that match our expectations or update logic
            -- The existing mock for bufadd (in navigation_spec) extracts numbers from filenames.
            -- Here we should probably ensure bufadd behaves predictably.
            -- navigation_spec uses:
            -- stub(vim.fn, "bufadd").invokes(function(filename)
            --    local bufnr = tonumber(filename:match("file(%d+)%.lua"))
            --    return bufnr or 1
            -- end)

            -- Let's update bufadd stub for this test
            stub(vim.fn, "bufadd").invokes(function(filename)
                if filename:match("file1") then
                    return 1
                end
                if filename:match("file2") then
                    return 2
                end
                return 99
            end)

            -- Re-run restore to pick up new bufadd logic if needed,
            -- but bookmark.from_json doesn't call bufadd, bookmark.update_all does?
            -- persist.restore calls bookmark.update_all(bookmarks).
            -- bookmark.update_all just sets the table.
            -- BUT persist.restore calls `bookmark.update_bufnr()`? No, it calls `bookmark.from_json` then `bookmark.update_all`.
            -- bookmark.list() calls update_bufnr().

            -- Let's just check if they exist in memory
            local list = bookmark.list()
            assert.are.equal(2, #list)

            -- Verify specific bookmarks
            -- We need to check existence with correct bufnr.
            -- bookmark.list() calls update_bufnr() which calls bufadd.
            -- So our bufadd stub above will be used.

            assert.is_true(bookmark.exists(1, 10))
            assert.is_true(bookmark.exists(2, 20))
        end)

        it("should handle corrupted bookmark file gracefully", function()
            -- corrupted json
            mock.set_file_contents(expected_path, { "{ invalid json" })

            config.setup()

            -- Should not crash
            local status = pcall(persist.restore)
            assert.is_true(status)

            -- Should have empty bookmarks
            assert.are.equal(0, #bookmark.list())
        end)

        it("should filter out invalid bookmarks (e.g. line number out of range)", function()
            local saved_bookmarks = {
                { filename = "/test/project/file1.lua", bufnr = 1, lnum = 9999 }, -- invalid line
            }
            local json_str = vim.json.encode(saved_bookmarks)
            mock.set_file_contents(expected_path, { json_str })

            -- Mock file validation to fail for line 9999
            local file = require("bookmarks.file")
            file.get_max_lnum = function()
                return 100
            end

            config.setup()
            persist.restore()

            assert.are.equal(0, #bookmark.list())
        end)
    end)
end)
