-- Tests for bookmarks/extmark.lua

describe("extmark", function()
    local extmark
    local mock_ns_id = 123
    local mock_extmark_id_counter = 1000

    -- Mock Neovim extmark APIs
    local original_create_namespace
    local original_buf_set_extmark
    local original_buf_del_extmark
    local original_buf_get_extmark_by_id

    -- Track extmark state for testing
    local extmark_positions = {} -- extmark_id -> {bufnr, lnum}

    before_each(function()
        -- Reset modules
        package.loaded["bookmarks.extmark"] = nil
        package.loaded["bookmarks.config"] = nil

        -- Reset mock state
        mock_extmark_id_counter = 1000
        extmark_positions = {}

        -- Store original functions
        original_create_namespace = vim.api.nvim_create_namespace
        original_buf_set_extmark = vim.api.nvim_buf_set_extmark
        original_buf_del_extmark = vim.api.nvim_buf_del_extmark
        original_buf_get_extmark_by_id = vim.api.nvim_buf_get_extmark_by_id

        -- Mock nvim_create_namespace
        vim.api.nvim_create_namespace = function(name)
            return mock_ns_id
        end

        -- Mock nvim_buf_set_extmark
        vim.api.nvim_buf_set_extmark = function(bufnr, ns_id, lnum, col, opts)
            mock_extmark_id_counter = mock_extmark_id_counter + 1
            local extmark_id = mock_extmark_id_counter
            extmark_positions[extmark_id] = { bufnr = bufnr, lnum = lnum }
            return extmark_id
        end

        -- Mock nvim_buf_del_extmark
        vim.api.nvim_buf_del_extmark = function(bufnr, ns_id, extmark_id)
            extmark_positions[extmark_id] = nil
        end

        -- Mock nvim_buf_get_extmark_by_id
        vim.api.nvim_buf_get_extmark_by_id = function(bufnr, ns_id, extmark_id, opts)
            local pos = extmark_positions[extmark_id]
            if pos then
                return { pos.lnum, 0 }
            end
            return {}
        end

        -- Load extmark module
        extmark = require("bookmarks.extmark")
    end)

    after_each(function()
        -- Restore original functions
        vim.api.nvim_create_namespace = original_create_namespace
        vim.api.nvim_buf_set_extmark = original_buf_set_extmark
        vim.api.nvim_buf_del_extmark = original_buf_del_extmark
        vim.api.nvim_buf_get_extmark_by_id = original_buf_get_extmark_by_id
    end)

    describe("add", function()
        it("should create extmark at specified position", function()
            local bufnr = 1
            local lnum = 10

            local extmark_id = extmark.add(bufnr, lnum)

            assert.is_number(extmark_id)
            assert.is_not_nil(extmark_positions[extmark_id])
        end)

        it("should use 0-indexed line number", function()
            local bufnr = 1
            local lnum = 10

            local extmark_id = extmark.add(bufnr, lnum)

            -- Extmark should be at lnum-1 (0-indexed)
            assert.are.equal(9, extmark_positions[extmark_id].lnum)
        end)

        it("should replace existing extmark at same position", function()
            local bufnr = 1
            local lnum = 10

            local first_id = extmark.add(bufnr, lnum)
            local second_id = extmark.add(bufnr, lnum)

            assert.are_not.equal(first_id, second_id)
            assert.is_nil(extmark_positions[first_id])
            assert.is_not_nil(extmark_positions[second_id])
        end)
    end)

    describe("get_extmark_id", function()
        it("should return extmark id for existing extmark", function()
            local bufnr = 1
            local lnum = 10

            local extmark_id = extmark.add(bufnr, lnum)
            local retrieved_id = extmark.get_extmark_id(bufnr, lnum)

            assert.are.equal(extmark_id, retrieved_id)
        end)

        it("should return nil for non-existing extmark", function()
            local retrieved_id = extmark.get_extmark_id(1, 10)
            assert.is_nil(retrieved_id)
        end)
    end)

    describe("delete", function()
        it("should remove extmark", function()
            local bufnr = 1
            local lnum = 10

            local extmark_id = extmark.add(bufnr, lnum)
            extmark.delete(bufnr, lnum)

            assert.is_nil(extmark_positions[extmark_id])
            assert.is_nil(extmark.get_extmark_id(bufnr, lnum))
        end)

        it("should handle deleting non-existing extmark", function()
            -- Should not error
            extmark.delete(1, 10)
        end)
    end)

    describe("clear_buffer", function()
        it("should remove all extmarks for buffer", function()
            local bufnr = 1

            local id1 = extmark.add(bufnr, 10)
            local id2 = extmark.add(bufnr, 20)
            local id3 = extmark.add(2, 30) -- Different buffer

            extmark.clear_buffer(bufnr)

            assert.is_nil(extmark_positions[id1])
            assert.is_nil(extmark_positions[id2])
            assert.is_not_nil(extmark_positions[id3]) -- Should remain
        end)
    end)

    describe("clear_all", function()
        it("should remove all extmarks", function()
            local id1 = extmark.add(1, 10)
            local id2 = extmark.add(2, 20)

            extmark.clear_all()

            assert.is_nil(extmark_positions[id1])
            assert.is_nil(extmark_positions[id2])
        end)
    end)

    describe("get_position_changes", function()
        it("should detect position changes", function()
            local bufnr = 1
            local extmark_id = extmark.add(bufnr, 10)

            -- Simulate extmark moving to line 15 (14 in 0-indexed)
            extmark_positions[extmark_id].lnum = 14

            local changes = extmark.get_position_changes(bufnr)

            assert.are.equal(15, changes[10])
        end)

        it("should return empty table when no changes", function()
            local bufnr = 1
            extmark.add(bufnr, 10)

            local changes = extmark.get_position_changes(bufnr)

            assert.are.same({}, changes)
        end)

        it("should handle multiple changes", function()
            local bufnr = 1
            local id1 = extmark.add(bufnr, 10)
            local id2 = extmark.add(bufnr, 20)

            -- Simulate both extmarks moving
            extmark_positions[id1].lnum = 14 -- 10 -> 15 (1-indexed)
            extmark_positions[id2].lnum = 24 -- 20 -> 25 (1-indexed)

            local changes = extmark.get_position_changes(bufnr)

            assert.are.equal(15, changes[10])
            assert.are.equal(25, changes[20])
        end)
    end)

    describe("update_lnum", function()
        it("should update internal tracking", function()
            local bufnr = 1
            extmark.add(bufnr, 10)

            extmark.update_lnum(bufnr, 10, 15)

            assert.is_nil(extmark.get_extmark_id(bufnr, 10))
            assert.is_not_nil(extmark.get_extmark_id(bufnr, 15))
        end)

        it("should preserve extmark id", function()
            local bufnr = 1
            local original_id = extmark.add(bufnr, 10)

            extmark.update_lnum(bufnr, 10, 15)

            local new_id = extmark.get_extmark_id(bufnr, 15)
            assert.are.equal(original_id, new_id)
        end)
    end)
end)
