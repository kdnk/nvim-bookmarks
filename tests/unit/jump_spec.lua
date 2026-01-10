-- Tests for bookmarks/jump.lua

local mock = require("tests.helpers.mock")
local stub = require("luassert.stub")

describe("jump", function()
    local jump
    local bookmark
    local file

    -- Mock vim API calls for cursor and buffer management
    local cursor_position = { 1, 0 }
    local current_bufnr = 0
    local current_win = 1000

    before_each(function()
        -- Reset modules
        package.loaded["bookmarks.jump"] = nil
        package.loaded["bookmarks.bookmark"] = nil
        package.loaded["bookmarks.file"] = nil
        package.loaded["bookmarks.core"] = nil

        -- Reset state
        cursor_position = { 1, 0 }
        current_bufnr = 0

        -- Setup mocks
        mock.setup_vim_api()

        -- Mock additional vim APIs for jump
        stub(vim.api, "nvim_get_current_win").returns(current_win)
        stub(vim.api, "nvim_win_get_cursor").invokes(function(win)
            return cursor_position
        end)
        stub(vim.api, "nvim_set_current_buf").invokes(function(bufnr)
            current_bufnr = bufnr
        end)
        stub(vim.api, "nvim_win_set_cursor").invokes(function(win, pos)
            cursor_position = pos
        end)

        -- Stub vim.fn.bufadd to return the filename's bufnr
        stub(vim.fn, "bufadd").invokes(function(filename)
            -- Extract bufnr from filename (e.g., "/test/file1.lua" -> 1)
            local bufnr = tonumber(filename:match("file(%d+)%.lua"))
            return bufnr or 1
        end)

        -- Mock file module
        file = require("bookmarks.file")
        file.get_max_lnum = function(filename)
            return 1000
        end

        -- Load modules
        bookmark = require("bookmarks.bookmark")
        jump = require("bookmarks.jump")
    end)

    after_each(function()
        bookmark.remove_all()
        jump.reset_index()
        mock.teardown()
    end)

    describe("get_index", function()
        it("should start at index 1", function()
            assert.are.equal(1, jump.get_index())
        end)
    end)

    describe("reset_index", function()
        it("should reset index to 1", function()
            -- Manually set index by jumping
            mock.set_buf_name(1, "/test/file.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)
            jump.jump({ reverse = false })

            jump.reset_index()
            assert.are.equal(1, jump.get_index())
        end)
    end)

    describe("jump with empty bookmarks", function()
        it("should do nothing when no bookmarks exist", function()
            local original_bufnr = current_bufnr
            jump.jump({ reverse = false })
            assert.are.equal(original_bufnr, current_bufnr)
        end)
    end)

    describe("jump forward", function()
        it("should jump to next bookmark", function()
            mock.set_buf_name(1, "/test/file.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)

            jump.jump({ reverse = false })

            -- Jump goes to first bookmark in the list
            assert.are.equal(1, current_bufnr)
            -- The actual lnum depends on list order
            assert.is_true(cursor_position[1] == 10 or cursor_position[1] == 20)
        end)

        it("should wrap around to first bookmark", function()
            mock.set_buf_name(1, "/test/file.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)

            -- Jump to first
            jump.jump({ reverse = false })
            local first_pos = cursor_position[1]

            -- Jump to second
            jump.jump({ reverse = false })

            -- Jump again should wrap back to first
            jump.jump({ reverse = false })

            assert.are.equal(first_pos, cursor_position[1])
        end)

        it("should jump across files", function()
            mock.set_buf_name(1, "/test/file1.lua")
            mock.set_buf_name(2, "/test/file2.lua")
            bookmark.add(1, 10)
            bookmark.add(2, 20)

            jump.jump({ reverse = false })
            local first_bufnr = current_bufnr

            jump.jump({ reverse = false })
            local second_bufnr = current_bufnr

            assert.are_not.equal(first_bufnr, second_bufnr)
        end)
    end)

    describe("jump backward", function()
        it("should jump to previous bookmark", function()
            mock.set_buf_name(1, "/test/file.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)

            -- Move forward first
            jump.jump({ reverse = false })
            local first_pos = cursor_position[1]
            jump.jump({ reverse = false })
            local second_pos = cursor_position[1]

            -- Now jump backward should return to first
            jump.jump({ reverse = true })

            assert.are.equal(first_pos, cursor_position[1])
        end)

        it("should wrap around to last bookmark", function()
            mock.set_buf_name(1, "/test/file.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)

            -- From index 1, jumping backward should wrap to last
            jump.jump({ reverse = true })

            -- Should be at a bookmark (wraps to last)
            assert.are.equal(1, current_bufnr)
            assert.is_true(cursor_position[1] == 10 or cursor_position[1] == 20)
        end)
    end)

    describe("jump within file", function()
        it("should jump to next bookmark in same file", function()
            mock.set_buf_name(0, "/test/file.lua")
            mock.set_buf_name(1, "/test/file.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)
            bookmark.add(1, 30)

            -- Set cursor at line 5 (before first bookmark)
            cursor_position = { 5, 0 }

            jump.jump({ reverse = false })

            -- Should jump to first bookmark at line 10
            assert.are.equal(10, cursor_position[1])
        end)

        it("should jump to previous bookmark in same file", function()
            mock.set_buf_name(0, "/test/file.lua")
            mock.set_buf_name(1, "/test/file.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)
            bookmark.add(1, 30)

            -- Set cursor at line 25 (between 20 and 30)
            cursor_position = { 25, 0 }

            jump.jump({ reverse = true })

            -- Should jump to bookmark at line 20
            assert.are.equal(20, cursor_position[1])
        end)

        it("should jump across files when no bookmark in current file", function()
            mock.set_buf_name(0, "/test/file1.lua")
            mock.set_buf_name(1, "/test/file1.lua")
            mock.set_buf_name(2, "/test/file2.lua")
            bookmark.add(2, 20) -- Only bookmark in file2

            cursor_position = { 5, 0 }

            jump.jump({ reverse = false })

            -- Should jump to a bookmark (file2)
            assert.are.equal(20, cursor_position[1])
        end)
    end)

    describe("single bookmark", function()
        it("should stay on same bookmark when jumping", function()
            mock.set_buf_name(1, "/test/file.lua")
            bookmark.add(1, 10)

            jump.jump({ reverse = false })
            local first_lnum = cursor_position[1]

            jump.jump({ reverse = false })
            local second_lnum = cursor_position[1]

            assert.are.equal(first_lnum, second_lnum)
            assert.are.equal(10, first_lnum)
        end)
    end)

    describe("index management", function()
        it("should increment index on forward jump", function()
            mock.set_buf_name(1, "/test/file.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)
            bookmark.add(1, 30)

            local initial_index = jump.get_index()
            jump.jump({ reverse = false })
            local after_first = jump.get_index()
            jump.jump({ reverse = false })
            local after_second = jump.get_index()

            assert.are.equal(1, initial_index)
            assert.is_true(after_first > initial_index or after_first == 1) -- Could wrap
            assert.is_true(after_second > after_first or after_second == 1) -- Could wrap
        end)

        it("should decrement index on backward jump", function()
            mock.set_buf_name(1, "/test/file.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)
            bookmark.add(1, 30)

            -- Start at index 1
            jump.jump({ reverse = true })

            -- Should wrap to last index
            local index = jump.get_index()
            assert.is_true(index > 1)
        end)
    end)
end)
