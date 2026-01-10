-- Tests for core/lua.lua utility functions

local lua = require("bookmarks.core.lua")

describe("core.lua", function()
    describe("string", function()
        describe("split", function()
            it("should split string by separator", function()
                local result = lua.string.split("a,b,c", ",")
                assert.are.same({ "a", "b", "c" }, result)
            end)

            it("should handle empty parts", function()
                local result = lua.string.split("a,,c", ",")
                assert.are.same({ "a", "", "c" }, result)
            end)

            it("should handle string without separator", function()
                local result = lua.string.split("abc", ",")
                assert.are.same({ "abc" }, result)
            end)

            it("should handle empty string", function()
                local result = lua.string.split("", ",")
                assert.are.same({}, result)
            end)
        end)
    end)

    describe("list", function()
        describe("map", function()
            it("should transform all elements", function()
                local list = { 1, 2, 3 }
                local result = lua.list.map(list, function(v)
                    return v * 2
                end)
                assert.are.same({ 2, 4, 6 }, result)
            end)

            it("should pass index to callback", function()
                local list = { "a", "b", "c" }
                local result = lua.list.map(list, function(v, i)
                    return v .. i
                end)
                assert.are.same({ "a1", "b2", "c3" }, result)
            end)
        end)

        describe("filter", function()
            it("should keep matching elements", function()
                local list = { 1, 2, 3, 4, 5 }
                local result = lua.list.filter(list, function(v)
                    return v > 2
                end)
                assert.are.same({ 3, 4, 5 }, result)
            end)

            it("should return empty list if no matches", function()
                local list = { 1, 2, 3 }
                local result = lua.list.filter(list, function(v)
                    return v > 10
                end)
                assert.are.same({}, result)
            end)
        end)

        describe("includes", function()
            it("should return true if element exists", function()
                local list = { 1, 2, 3 }
                local result = lua.list.includes(list, function(v)
                    return v == 2
                end)
                assert.is_true(result)
            end)

            it("should return false if element doesn't exist", function()
                local list = { 1, 2, 3 }
                local result = lua.list.includes(list, function(v)
                    return v == 5
                end)
                assert.is_false(result)
            end)
        end)

        describe("find", function()
            it("should return first matching element", function()
                local list = { 1, 2, 3, 2 }
                local result = lua.list.find(list, function(v)
                    return v == 2
                end)
                assert.are.equal(2, result)
            end)

            it("should return nil if no match", function()
                local list = { 1, 2, 3 }
                local result = lua.list.find(list, function(v)
                    return v == 5
                end)
                assert.is_nil(result)
            end)
        end)

        describe("find_index", function()
            it("should return index of first match", function()
                local list = { "a", "b", "c", "b" }
                local result = lua.list.find_index(list, function(v)
                    return v == "b"
                end)
                assert.are.equal(2, result)
            end)

            it("should return nil if no match", function()
                local list = { "a", "b", "c" }
                local result = lua.list.find_index(list, function(v)
                    return v == "d"
                end)
                assert.is_nil(result)
            end)
        end)

        describe("find_last_index", function()
            it("should return index of last match", function()
                local list = { "a", "b", "c", "b" }
                local result = lua.list.find_last_index(list, function(v)
                    return v == "b"
                end)
                assert.are.equal(4, result)
            end)

            it("should return nil if no match", function()
                local list = { "a", "b", "c" }
                local result = lua.list.find_last_index(list, function(v)
                    return v == "d"
                end)
                assert.is_nil(result)
            end)
        end)

        describe("sort", function()
            it("should sort with custom comparison", function()
                local list = { 3, 1, 2 }
                local result = lua.list.sort(list, function(prev, cur)
                    return prev > cur
                end)
                assert.are.same({ 1, 2, 3 }, result)
            end)

            it("should handle descending sort", function()
                local list = { 1, 3, 2 }
                local result = lua.list.sort(list, function(prev, cur)
                    return prev < cur
                end)
                assert.are.same({ 3, 2, 1 }, result)
            end)
        end)

        describe("each", function()
            it("should iterate over all elements", function()
                local list = { 1, 2, 3 }
                local sum = 0
                lua.list.each(list, function(v)
                    sum = sum + v
                end)
                assert.are.equal(6, sum)
            end)

            it("should pass index to callback", function()
                local list = { "a", "b", "c" }
                local indices = {}
                lua.list.each(list, function(v, i)
                    table.insert(indices, i)
                end)
                assert.are.same({ 1, 2, 3 }, indices)
            end)
        end)

        describe("uniq", function()
            it("should remove duplicates", function()
                local list = { 1, 2, 2, 3, 1 }
                local result = lua.list.uniq(list)
                assert.are.same({ 1, 2, 3 }, result)
            end)

            it("should preserve order", function()
                local list = { 3, 1, 2, 1, 3 }
                local result = lua.list.uniq(list)
                assert.are.same({ 3, 1, 2 }, result)
            end)
        end)

        describe("merge", function()
            it("should merge two lists", function()
                local list1 = { 1, 2, 3 }
                local list2 = { 3, 4, 5 }
                local result = lua.list.merge(list1, list2)
                assert.are.same({ 1, 2, 3, 4, 5 }, result)
            end)

            it("should not duplicate elements from list2", function()
                local list1 = { 1, 2 }
                local list2 = { 2, 3 }
                local result = lua.list.merge(list1, list2)
                assert.are.same({ 1, 2, 3 }, result)
            end)
        end)

        describe("reduce", function()
            it("should accumulate values", function()
                local list = { 1, 2, 3, 4 }
                local result = lua.list.reduce(list, function(acc, v)
                    return acc + v
                end, 0)
                assert.are.equal(10, result)
            end)

            it("should pass list to callback", function()
                local list = { 1, 2, 3 }
                local result = lua.list.reduce(list, function(acc, v, l)
                    return acc + #l
                end, 0)
                assert.are.equal(9, result) -- 3 items * 3 length
            end)
        end)
    end)

    describe("table", function()
        describe("clone", function()
            it("should deep clone table", function()
                local original = { a = 1, b = { c = 2 } }
                local cloned = lua.table.clone(original)

                cloned.a = 10
                cloned.b.c = 20

                assert.are.equal(1, original.a)
                assert.are.equal(2, original.b.c)
                assert.are.equal(10, cloned.a)
                assert.are.equal(20, cloned.b.c)
            end)

            it("should handle non-table values", function()
                local result = lua.table.clone(42)
                assert.are.equal(42, result)
            end)
        end)

        describe("each", function()
            it("should iterate over key-value pairs", function()
                local t = { a = 1, b = 2, c = 3 }
                local sum = 0
                lua.table.each(t, function(k, v)
                    sum = sum + v
                end)
                assert.are.equal(6, sum)
            end)
        end)

        describe("map", function()
            it("should transform values", function()
                local t = { a = 1, b = 2, c = 3 }
                local result = lua.table.map(t, function(v)
                    return v * 2
                end)
                assert.are.same({ a = 2, b = 4, c = 6 }, result)
            end)
        end)

        describe("reduce", function()
            it("should accumulate from table", function()
                local t = { a = 1, b = 2, c = 3 }
                local result = lua.table.reduce(t, function(acc, item)
                    return acc + item.v
                end, 0)
                assert.are.equal(6, result)
            end)
        end)

        describe("keys", function()
            it("should extract all keys", function()
                local t = { a = 1, b = 2, c = 3 }
                local keys = lua.table.keys(t)
                table.sort(keys)
                assert.are.same({ "a", "b", "c" }, keys)
            end)
        end)

        describe("is_empty", function()
            it("should return true for empty table", function()
                local t = {}
                assert.is_true(lua.table.is_empty(t))
            end)

            it("should return false for non-empty table", function()
                local t = { a = 1 }
                assert.is_false(lua.table.is_empty(t))
            end)
        end)
    end)
end)
