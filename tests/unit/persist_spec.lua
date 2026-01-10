-- Tests for bookmarks/persist.lua

local mock = require("tests.helpers.mock")
local stub = require("luassert.stub")
local match = require("luassert.match")

describe("persist", function()
    local persist
    local bookmark
    local config
    local file
    local sync

    -- Mock state
    local test_cwd = "/test/project"
    local test_data_dir = "/test/data"
    local test_branch = "main"

    before_each(function()
        -- Reset modules
        package.loaded["bookmarks.persist"] = nil
        package.loaded["bookmarks.bookmark"] = nil
        package.loaded["bookmarks.config"] = nil
        package.loaded["bookmarks.file"] = nil
        package.loaded["bookmarks.sync"] = nil
        package.loaded["bookmarks.core"] = nil

        -- Setup basic mocks
        mock.setup_vim_api()
        mock.setup_file_io()
        mock.setup_git()

        -- Stub vim functions for path generation
        stub(vim.fn, "getcwd").returns(test_cwd)
        stub(vim.fn, "stdpath").invokes(function(what)
            if what == "data" then
                return test_data_dir
            end
            return ""
        end)
        stub(vim.fn, "sha256").invokes(function(str)
            -- Simple deterministic hash for testing
            return string.rep("a", 64) -- 64 character hash
        end)
        stub(vim.fn, "sign_define") -- Mock sign_define

        -- Mock file module
        file = require("bookmarks.file")
        file.get_max_lnum = function(filename)
            return 1000
        end

        -- Load modules
        config = require("bookmarks.config")
        config.setup() -- Initialize config with defaults
        bookmark = require("bookmarks.bookmark")
        sync = require("bookmarks.sync")

        -- Mock sync functions
        stub(sync, "bookmarks_to_signs")
        stub(sync, "bookmarks_to_extmarks")

        -- Load persist after mocks are set up
        persist = require("bookmarks.persist")
    end)

    after_each(function()
        bookmark.remove_all()
        mock.teardown()
    end)

    describe("backup", function()
        it("should write bookmarks to JSON when enabled", function()
            config.persist.enable = true
            mock.set_buf_name(1, "/test/file.lua")
            bookmark.add(1, 10)

            persist.backup()

            -- Check that file was written
            local written_path = test_data_dir .. "/nvim-bookmarks/aaaaaaaaaaaaaaaa/main.json"
            local written = mock.get_written_file(written_path)
            assert.is_not_nil(written)
        end)

        it("should not write when persist is disabled", function()
            config.persist.enable = false
            mock.set_buf_name(1, "/test/file.lua")
            bookmark.add(1, 10)

            persist.backup()

            -- No files should be written
            local written_path = test_data_dir .. "/nvim-bookmarks/aaaaaaaaaaaaaaaa/main.json"
            local written = mock.get_written_file(written_path)
            assert.is_nil(written)
        end)

        it("should use branch-specific path when per_branch is enabled", function()
            config.persist.enable = true
            config.persist.per_branch = true
            mock.set_git_branch("feature/test")
            mock.set_buf_name(1, "/test/file.lua")
            bookmark.add(1, 10)

            persist.backup()

            -- Branch name should be sanitized (/ replaced with _)
            local written_path = test_data_dir .. "/nvim-bookmarks/aaaaaaaaaaaaaaaa/feature_test.json"
            local written = mock.get_written_file(written_path)
            assert.is_not_nil(written)
        end)

        it("should use common path when per_branch is disabled", function()
            config.persist.enable = true
            config.persist.per_branch = false
            mock.set_buf_name(1, "/test/file.lua")
            bookmark.add(1, 10)

            persist.backup()

            local written_path = test_data_dir .. "/nvim-bookmarks/aaaaaaaaaaaaaaaa/bookmarks.json"
            local written = mock.get_written_file(written_path)
            assert.is_not_nil(written)
        end)

        it("should sanitize branch names with unsafe characters", function()
            config.persist.enable = true
            config.persist.per_branch = true
            mock.set_git_branch("feature/test:branch*name")
            mock.set_buf_name(1, "/test/file.lua")
            bookmark.add(1, 10)

            persist.backup()

            -- All unsafe chars should be replaced with _
            local written_path = test_data_dir .. "/nvim-bookmarks/aaaaaaaaaaaaaaaa/feature_test_branch_name.json"
            local written = mock.get_written_file(written_path)
            assert.is_not_nil(written)
        end)

        it("should use default branch when no git branch", function()
            config.persist.enable = true
            config.persist.per_branch = true
            mock.set_git_branch("")
            mock.set_buf_name(1, "/test/file.lua")
            bookmark.add(1, 10)

            persist.backup()

            local written_path = test_data_dir .. "/nvim-bookmarks/aaaaaaaaaaaaaaaa/default.json"
            local written = mock.get_written_file(written_path)
            assert.is_not_nil(written)
        end)
    end)

    describe("restore", function()
        it("should return empty when persist is disabled", function()
            config.persist.enable = false

            local result = persist.restore()

            assert.are.same({}, result)
        end)

        it("should return empty when file doesn't exist", function()
            config.persist.enable = true

            local result = persist.restore()

            assert.are.same({}, result)
        end)

        it("should load bookmarks from JSON file", function()
            config.persist.enable = true

            -- Setup mock file with bookmarks
            local file_path = test_data_dir .. "/nvim-bookmarks/aaaaaaaaaaaaaaaa/main.json"
            local json_data = vim.json.encode({
                { filename = "/test/file.lua", bufnr = 1, lnum = 10 },
                { filename = "/test/file.lua", bufnr = 1, lnum = 20 },
            })
            mock.set_file_contents(file_path, { json_data })

            persist.restore()

            -- Bookmarks should be loaded
            assert.is_true(bookmark.exists(1, 10))
            assert.is_true(bookmark.exists(1, 20))
        end)

        it("should call sync.bookmarks_to_signs after restore", function()
            config.persist.enable = true

            local file_path = test_data_dir .. "/nvim-bookmarks/aaaaaaaaaaaaaaaa/main.json"
            local json_data = vim.json.encode({
                { filename = "/test/file.lua", bufnr = 1, lnum = 10 },
            })
            mock.set_file_contents(file_path, { json_data })

            persist.restore()

            assert.stub(sync.bookmarks_to_signs).was_called()
        end)

        it("should create BufEnter autocmd for extmarks", function()
            config.persist.enable = true

            local file_path = test_data_dir .. "/nvim-bookmarks/aaaaaaaaaaaaaaaa/main.json"
            local json_data = vim.json.encode({
                { filename = "/test/file.lua", bufnr = 1, lnum = 10 },
            })
            mock.set_file_contents(file_path, { json_data })

            -- Stub nvim_create_autocmd to verify it's called
            local autocmd_stub = stub(vim.api, "nvim_create_autocmd")

            persist.restore()

            -- Should create autocmd
            assert.stub(autocmd_stub).was_called()
            assert.stub(autocmd_stub).was_called_with("BufEnter", match.is_table())

            autocmd_stub:revert()
        end)
    end)

    describe("path generation", function()
        it("should generate consistent project hash", function()
            config.persist.enable = true
            mock.set_buf_name(1, "/test/file.lua")
            bookmark.add(1, 10)

            persist.backup()

            -- Hash should be first 16 chars of sha256
            local expected_path = test_data_dir .. "/nvim-bookmarks/aaaaaaaaaaaaaaaa/main.json"
            local written = mock.get_written_file(expected_path)
            assert.is_not_nil(written)
        end)
    end)
end)
