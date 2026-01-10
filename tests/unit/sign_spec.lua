-- Tests for bookmarks/sign.lua

local stub = require("luassert.stub")

describe("sign", function()
    local sign
    local config

    -- Mock sign state
    local placed_signs = {}
    local next_sign_id = 1

    before_each(function()
        -- Reset modules
        package.loaded["bookmarks.sign"] = nil
        package.loaded["bookmarks.config"] = nil
        package.loaded["bookmarks.core"] = nil

        -- Reset state
        placed_signs = {}
        next_sign_id = 1

        -- Stub vim sign functions
        stub(vim.fn, "sign_place").invokes(function(id, group, name, bufnr, opts)
            local sign_id = id == 0 and next_sign_id or id
            next_sign_id = next_sign_id + 1
            placed_signs[sign_id] = {
                id = sign_id,
                group = group,
                name = name,
                bufnr = bufnr,
                lnum = opts.lnum,
                priority = opts.priority,
            }
            return sign_id
        end)

        stub(vim.fn, "sign_unplace").invokes(function(group, opts)
            if opts and opts.id then
                placed_signs[opts.id] = nil
            elseif opts == nil then
                placed_signs = {}
            end
        end)

        stub(vim.fn, "sign_getplaced").invokes(function(bufnr, opts)
            local signs = {}
            for _, s in pairs(placed_signs) do
                if s.bufnr == bufnr then
                    if not opts or not opts.lnum or s.lnum == opts.lnum then
                        if not opts or not opts.group or s.group == opts.group then
                            table.insert(signs, s)
                        end
                    end
                end
            end
            return { { signs = signs } }
        end)

        stub(vim.fn, "sign_define")

        -- Load modules
        config = require("bookmarks.config")
        config.setup()
        sign = require("bookmarks.sign")
    end)

    after_each(function()
        placed_signs = {}
    end)

    describe("add", function()
        it("should place sign at specified position", function()
            sign.add(1, 10)

            -- Check that sign was placed
            assert.is_true(#placed_signs > 0)
        end)

        it("should use configured sign group and name", function()
            sign.add(1, 10)

            local placed = placed_signs[1]
            assert.are.equal("Bookmark", placed.group)
            assert.are.equal("Bookmark", placed.name)
        end)

        it("should set priority to 1000", function()
            sign.add(1, 10)

            local placed = placed_signs[1]
            assert.are.equal(1000, placed.priority)
        end)
    end)

    describe("delete", function()
        it("should remove sign at position", function()
            sign.add(1, 10)
            local count_before = 0
            for _ in pairs(placed_signs) do
                count_before = count_before + 1
            end

            sign.delete(1, 10)

            local count_after = 0
            for _ in pairs(placed_signs) do
                count_after = count_after + 1
            end

            assert.is_true(count_after < count_before)
        end)
    end)

    describe("remove_all", function()
        it("should remove all signs", function()
            sign.add(1, 10)
            sign.add(1, 20)
            sign.add(2, 30)

            sign.remove_all()

            local count = 0
            for _ in pairs(placed_signs) do
                count = count + 1
            end

            assert.are.equal(0, count)
        end)
    end)
end)
