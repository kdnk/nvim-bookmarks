local mock = require("tests.helpers.mock")

describe("lualine", function()
    local lualine
    local bookmark
    local jump

    before_each(function()
        package.loaded["bookmarks.lualine"] = nil
        package.loaded["bookmarks.bookmark"] = nil
        package.loaded["bookmarks.jump"] = nil

        mock.setup_vim_api()

        bookmark = require("bookmarks.bookmark")
        jump = require("bookmarks.jump")
        lualine = require("bookmarks.lualine")
    end)

    after_each(function()
        mock.teardown()
    end)

    describe("bookmark_count", function()
        it("should return formatted string with 7 bytes width when total is 0", function()
            -- Mock bookmark.list to return empty list
            bookmark.list = function()
                return {}
            end

            local result = lualine.bookmark_count()
            assert.is.equal("⚑ 0/0", result)
            assert.is.equal(7, #result)
        end)

        it("should return formatted string with 7 bytes width when total > 0 and no jump index", function()
            bookmark.list = function()
                return { {}, {} }
            end -- 2 bookmarks
            jump.get_index = function()
                return 0
            end

            local result = lualine.bookmark_count()
            assert.is.equal("⚑ -/2", result)
            assert.is.equal(7, #result)
        end)

        it("should return formatted string with 7 bytes width when total > 0 and has jump index", function()
            bookmark.list = function()
                return { {}, {} }
            end -- 2 bookmarks
            jump.get_index = function()
                return 1
            end

            local result = lualine.bookmark_count()
            assert.is.equal("⚑ 1/2", result)
            assert.is.equal(7, #result)
        end)

        it("should return formatted string when result exceeds 7 bytes", function()
            bookmark.list = function()
                local list = {}
                for i = 1, 10 do
                    table.insert(list, {})
                end
                return list
            end -- 10 bookmarks
            jump.get_index = function()
                return 1
            end

            local result = lualine.bookmark_count()
            assert.is.equal("⚑ 1/10", result)
            assert.is.equal(8, #result)
        end)
    end)
end)