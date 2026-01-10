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
    local buffer_line_count = 1000

    before_each(function()
        -- Reset modules
        package.loaded["bookmarks.jump"] = nil
        package.loaded["bookmarks.bookmark"] = nil
        package.loaded["bookmarks.file"] = nil
        package.loaded["bookmarks.core"] = nil

        -- Reset state
        cursor_position = { 1, 0 }
        current_bufnr = 0
        buffer_line_count = 1000

        -- Setup mocks
        mock.setup_vim_api()

        -- Mock additional vim APIs for jump
        stub(vim.api, "nvim_get_current_win").returns(current_win)
        stub(vim.api, "nvim_get_current_buf").invokes(function()
            return current_bufnr
        end)
        stub(vim.api, "nvim_win_get_cursor").invokes(function(win)
            return cursor_position
        end)
        stub(vim.api, "nvim_set_current_buf").invokes(function(bufnr)
            current_bufnr = bufnr
        end)
        stub(vim.api, "nvim_win_set_cursor").invokes(function(win, pos)
            cursor_position = pos
        end)
        stub(vim.api, "nvim_buf_line_count").invokes(function()
            return buffer_line_count
        end)
        stub(vim.api, "nvim_buf_is_valid").returns(true)

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

    describe("jump with empty bookmarks", function()
        it("should do nothing when no bookmarks exist", function()
            local original_bufnr = current_bufnr
            jump.jump({ reverse = false })
            assert.are.equal(original_bufnr, current_bufnr)
        end)
    end)

    describe("jump forward", function()
        it("should jump to next bookmark", function()
            mock.set_buf_name(1, "/test/file1.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)

            jump.jump({ reverse = false })

            assert.are.equal(1, current_bufnr)
            assert.is_true(cursor_position[1] == 10 or cursor_position[1] == 20)
        end)

        it("should wrap around to first bookmark", function()
            mock.set_buf_name(1, "/test/file1.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)

            -- Initial jump to first
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

            -- From start, jump to file1
            jump.jump({ reverse = false })
            assert.are.equal(1, current_bufnr)

            -- Next jump to file2
            jump.jump({ reverse = false })
            assert.are.equal(2, current_bufnr)
        end)
    end)

    describe("jump backward", function()
        it("should jump to previous bookmark", function()
            mock.set_buf_name(1, "/test/file1.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)

            -- Move forward to second bookmark
            jump.jump({ reverse = false })
            jump.jump({ reverse = false })
            local second_pos = cursor_position[1]

            -- Now jump backward should return to first
            jump.jump({ reverse = true })
            assert.are_not.equal(second_pos, cursor_position[1])
        end)

        it("should wrap around to last bookmark", function()
            mock.set_buf_name(1, "/test/file1.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)

            -- Jumping backward from beginning should wrap to last
            jump.jump({ reverse = true })

            assert.are.equal(1, current_bufnr)
            -- Should be the last bookmark (20 in this case if sorted correctly)
            assert.are.equal(20, cursor_position[1])
        end)
    end)

    describe("jump within file", function()
        it("should jump to next bookmark in same file", function()
            mock.set_buf_name(0, "/test/file1.lua")
            mock.set_buf_name(1, "/test/file1.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)
            bookmark.add(1, 30)

            -- Set cursor before first bookmark
            cursor_position = { 5, 0 }

            jump.jump({ reverse = false })
            assert.are.equal(10, cursor_position[1])
        end)

        it("should jump to previous bookmark in same file", function()
            mock.set_buf_name(0, "/test/file1.lua")
            mock.set_buf_name(1, "/test/file1.lua")
            bookmark.add(1, 10)
            bookmark.add(1, 20)
            bookmark.add(1, 30)

            -- Set cursor between 20 and 30
            cursor_position = { 25, 0 }

            jump.jump({ reverse = true })
            assert.are.equal(20, cursor_position[1])
        end)
    end)

    describe("single bookmark", function()
        it("should stay on same bookmark when jumping", function()
            mock.set_buf_name(1, "/test/file1.lua")
            bookmark.add(1, 10)

            jump.jump({ reverse = false })
            assert.are.equal(10, cursor_position[1])

            jump.jump({ reverse = false })
            assert.are.equal(10, cursor_position[1])
        end)
    end)

    describe("jump to deleted line", function()
        it("should NOT crash but remove bookmark when jumping to a deleted line", function()
            mock.set_buf_name(1, "/test/file1.lua")
            -- Bookmark at line 10
            bookmark.add(1, 10)

            -- Simulate file shrinking to 5 lines
            buffer_line_count = 5

            -- Spy on notify and delete
            local notify_spy = stub(vim, "notify")
            local delete_spy = stub(bookmark, "delete")

            -- Should not error now
            assert.has_no_error(function()
                jump.jump({ reverse = false })
            end)

            assert.stub(notify_spy).was_called()
            assert.stub(delete_spy).was_called_with(1, 10)
        end)
    end)
end)