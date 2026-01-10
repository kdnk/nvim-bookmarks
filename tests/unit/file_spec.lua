-- Tests for bookmarks/file.lua

local mock = require("tests.helpers.mock")

describe("file", function()
    local file

    before_each(function()
        -- Reset modules
        package.loaded["bookmarks.file"] = nil

        -- Setup mocks
        mock.setup_file_io()

        -- Load module
        file = require("bookmarks.file")
    end)

    after_each(function()
        mock.teardown()
    end)

    describe("exists", function()
        it("should return true when file exists", function()
            local path = "/test/file.txt"
            mock.set_file_exists(path, true)

            assert.is_true(file.exists(path))
        end)

        it("should return false when file doesn't exist", function()
            local path = "/test/nonexistent.txt"
            mock.set_file_exists(path, false)

            assert.is_false(file.exists(path))
        end)
    end)

    describe("json_read", function()
        it("should read JSON file contents", function()
            local path = "/test/data.json"
            local contents = { '{"key": "value"}' }
            mock.set_file_contents(path, contents)

            local result = file.json_read(path)

            assert.are.same(contents, result)
        end)

        it("should return empty table for non-existent file", function()
            local path = "/test/nonexistent.json"

            local result = file.json_read(path)

            assert.are.same({}, result)
        end)
    end)

    describe("json_write", function()
        it("should write JSON to file", function()
            local path = "/test/output.json"
            local data = { '{"test": true}' }

            file.json_write(data, path)

            local written = mock.get_written_file(path)
            assert.are.same(data, written)
        end)

        it("should create directories if they don't exist", function()
            local path = "/test/nested/dir/file.json"
            local data = { '{"nested": true}' }

            -- Should not error even with nested path
            file.json_write(data, path)

            local written = mock.get_written_file(path)
            assert.are.same(data, written)
        end)
    end)
end)
