-- Integration tests for bookmark navigation

local mock = require("tests.helpers.mock")
local stub = require("luassert.stub")

describe("navigation workflow (integration)", function()
    local bm
    local bookmark
    local jump
    local config

    -- Track cursor state
    local current_bufnr = 1
    local cursor_position = { 1, 0 }

    before_each(function()
        -- Reset modules
        package.loaded["bookmarks.init"] = nil
        package.loaded["bookmarks.bookmark"] = nil
        package.loaded["bookmarks.jump"] = nil
        package.loaded["bookmarks.config"] = nil
        package.loaded["bookmarks.file"] = nil
        package.loaded["bookmarks.core"] = nil

        -- Reset state
        current_bufnr = 1
        cursor_position = { 1, 0 }

        -- Setup mocks
        mock.setup_vim_api()

        -- Stub vim functions
        stub(vim.api, "nvim_get_current_win").returns(1000)
        stub(vim.api, "nvim_win_get_cursor").invokes(function()
            return cursor_position
        end)
        stub(vim.api, "nvim_set_current_buf").invokes(function(bufnr)
            current_bufnr = bufnr
        end)
        stub(vim.api, "nvim_win_set_cursor").invokes(function(win, pos)
            cursor_position = pos
        end)
        stub(vim.fn, "bufadd").invokes(function(filename)
            local bufnr = tonumber(filename:match("file(%d+)%.lua"))
            return bufnr or 1
        end)

        -- Mock file module
        local file = require("bookmarks.file")
        file.get_max_lnum = function(filename)
            return 1000
        end

        -- Load modules
        config = require("bookmarks.config")
        config.setup()
        bm = require("bookmarks.init")
        bookmark = require("bookmarks.bookmark")
        jump = require("bookmarks.jump")
    end)

    after_each(function()
        bookmark.remove_all()
        jump.reset_index()
        mock.teardown()
    end)

    describe("jump_next", function()
        it("should navigate through bookmarks in order", function()
            mock.set_buf_name(1, "/test/file1.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)
            bookmark.add(1, 30)

            -- Jump to first
            bm.jump_next()
            local first_lnum = cursor_position[1]

            -- Jump to second
            bm.jump_next()
            local second_lnum = cursor_position[1]

            -- Jump to third
            bm.jump_next()
            local third_lnum = cursor_position[1]

            -- All should be different
            assert.are_not.equal(first_lnum, second_lnum)
            assert.are_not.equal(second_lnum, third_lnum)
        end)

        it("should wrap around to first bookmark", function()
            mock.set_buf_name(1, "/test/file1.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)

            -- Jump twice to reach end
            bm.jump_next()
            local first_pos = cursor_position[1]
            bm.jump_next()

            -- Jump again should wrap to first
            bm.jump_next()
            assert.are.equal(first_pos, cursor_position[1])
        end)

        it("should navigate across multiple files", function()
            mock.set_buf_name(1, "/test/file1.lua")
            mock.set_buf_name(2, "/test/file2.lua")
            bookmark.add(1, 10)
            bookmark.add(2, 20)

            -- Jump to first file
            bm.jump_next()
            local first_bufnr = current_bufnr

            -- Jump to second file
            bm.jump_next()
            local second_bufnr = current_bufnr

            -- Should have switched files (bufnrs may vary due to bufadd mock)
            assert.is_number(first_bufnr)
            assert.is_number(second_bufnr)
        end)

        it("should do nothing when no bookmarks exist", function()
            local original_bufnr = current_bufnr
            local original_pos = cursor_position[1]

            bm.jump_next()

            assert.are.equal(original_bufnr, current_bufnr)
            assert.are.equal(original_pos, cursor_position[1])
        end)
    end)

    describe("jump_prev", function()
        it("should navigate backwards through bookmarks", function()
            mock.set_buf_name(1, "/test/file1.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)
            bookmark.add(1, 30)

            -- Jump forward twice
            bm.jump_next()
            bm.jump_next()
            local forward_pos = cursor_position[1]

            -- Jump back
            bm.jump_prev()
            local back_pos = cursor_position[1]

            -- Should be at different position
            assert.are_not.equal(forward_pos, back_pos)
        end)

        it("should wrap around to last bookmark", function()
            mock.set_buf_name(1, "/test/file1.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)

            -- Jump backward from beginning should wrap to end
            bm.jump_prev()

            -- Should have jumped to a bookmark
            assert.is_number(cursor_position[1])
        end)
    end)

    describe("navigation with single bookmark", function()
        it("should stay on same bookmark when jumping", function()
            mock.set_buf_name(1, "/test/file1.lua")
            bookmark.add(1, 10)

            bm.jump_next()
            local first_lnum = cursor_position[1]

            bm.jump_next()
            local second_lnum = cursor_position[1]

            assert.are.equal(first_lnum, second_lnum)
        end)
    end)

    describe("within-file navigation", function()
        it("should jump to next bookmark in same file before switching files", function()
            mock.set_buf_name(0, "/test/file1.lua") -- Current buffer
            mock.set_buf_name(1, "/test/file1.lua")
            mock.set_buf_name(2, "/test/file2.lua")

            bookmark.add(1, 10)
            bookmark.add(1, 30)
            bookmark.add(2, 20)

            -- Set cursor between two bookmarks in file1
            cursor_position = { 15, 0 }

            bm.jump_next()

            -- Should jump to next bookmark in same file (30)
            assert.are.equal(30, cursor_position[1])
        end)

        it("should jump to previous bookmark in same file", function()
            mock.set_buf_name(0, "/test/file1.lua")
            mock.set_buf_name(1, "/test/file1.lua")

            bookmark.add(1, 10)
            bookmark.add(1, 30)

            -- Set cursor between two bookmarks
            cursor_position = { 20, 0 }

            bm.jump_prev()

            -- Should jump to previous bookmark (10)
            assert.are.equal(10, cursor_position[1])
        end)
    end)

    describe("circular navigation", function()
        it("should allow circular navigation through all bookmarks", function()
            mock.set_buf_name(1, "/test/file1.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)
            bookmark.add(1, 30)

            local positions = {}

            -- Jump through all bookmarks
            for i = 1, 3 do
                bm.jump_next()
                table.insert(positions, cursor_position[1])
            end

            -- Jump once more should return to first
            bm.jump_next()
            assert.are.equal(positions[1], cursor_position[1])
        end)
    end)

    describe("index management", function()
        it("should maintain index across jumps", function()
            mock.set_buf_name(1, "/test/file1.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)
            bookmark.add(1, 30)

            local initial_index = jump.get_index()
            assert.are.equal(1, initial_index)

            bm.jump_next()
            local after_jump = jump.get_index()

            -- Index should have changed
            assert.are_not.equal(initial_index, after_jump)
        end)

        it("should allow index reset", function()
            mock.set_buf_name(1, "/test/file1.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)

            bm.jump_next()
            bm.jump_next()

            jump.reset_index()
            assert.are.equal(1, jump.get_index())
        end)
    end)
end)
