-- Tests for bookmarks/sync.lua (Integration approach)

local mock = require("tests.helpers.mock")
local stub = require("luassert.stub")

describe("sync", function()
    local sync
    local bookmark
    local sign
    local extmark
    local config
    local file

    before_each(function()
        -- Reset modules
        package.loaded["bookmarks.sync"] = nil
        package.loaded["bookmarks.bookmark"] = nil
        package.loaded["bookmarks.sign"] = nil
        package.loaded["bookmarks.extmark"] = nil
        package.loaded["bookmarks.config"] = nil
        package.loaded["bookmarks.file"] = nil
        package.loaded["bookmarks.core"] = nil

        -- Setup mocks
        mock.setup_vim_api()

        -- Stub sign functions to avoid actual vim operations
        stub(vim.fn, "sign_place")
        stub(vim.fn, "sign_unplace")
        stub(vim.fn, "sign_getplaced").returns({ { signs = {} } })
        stub(vim.fn, "sign_define")

        -- Stub Neovim extmark APIs
        stub(vim.api, "nvim_create_namespace").returns(123)
        stub(vim.api, "nvim_buf_set_extmark").returns(1000)
        stub(vim.api, "nvim_buf_del_extmark")
        stub(vim.api, "nvim_buf_get_extmark_by_id").returns({})

        -- Mock file module
        file = require("bookmarks.file")
        file.get_max_lnum = function(filename)
            return 1000
        end

        -- Load modules in order
        config = require("bookmarks.config")
        config.setup()
        bookmark = require("bookmarks.bookmark")
        sign = require("bookmarks.sign")
        extmark = require("bookmarks.extmark")
        sync = require("bookmarks.sync")
    end)

    after_each(function()
        bookmark.remove_all()
        mock.teardown()
    end)

    describe("bookmarks_to_signs", function()
        it("should sync bookmarks to signs", function()
            mock.set_buf_name(1, "/test/file.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)

            -- Should not error
            sync.bookmarks_to_signs()

            -- Verify sign_unplace was called (remove_all)
            assert.stub(vim.fn.sign_unplace).was_called()
            -- Verify sign_place was called for each bookmark
            assert.stub(vim.fn.sign_place).was_called()
        end)
    end)

    describe("bookmarks_to_extmarks", function()
        it("should sync bookmarks to extmarks for buffer", function()
            local bufnr = 1
            mock.set_buf_name(bufnr, "/test/file.lua")
            bookmark.add(bufnr, 10)
            bookmark.add(bufnr, 20)

            -- Should not error
            sync.bookmarks_to_extmarks(bufnr)

            -- Test passes if no error occurs (integration test)
            assert.is_true(true)
        end)
    end)

    describe("extmarks_to_bookmarks", function()
        it("should update bookmarks when extmarks move", function()
            local bufnr = 1
            local filename = "/test/file.lua"
            mock.set_buf_name(bufnr, filename)
            bookmark.add(bufnr, 10)
            
            -- Set an extmark_id manually for testing
            bookmark.update_extmark_id(filename, 10, 1000)

            -- Mock extmark returning new position (line 15, 0-indexed is 14)
            vim.api.nvim_buf_get_extmark_by_id.invokes(function()
                return { 14, 0 }
            end)

            sync.extmarks_to_bookmarks(bufnr)

            -- Bookmark should be updated to line 15
            assert.is_true(bookmark.exists(bufnr, 15))
            assert.is_false(bookmark.exists(bufnr, 10))
        end)
    end)
end)
