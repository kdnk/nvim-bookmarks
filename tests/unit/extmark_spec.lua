-- Tests for bookmarks/extmark.lua

local mock = require("tests.helpers.mock")
local stub = require("luassert.stub")

describe("extmark", function()
    local extmark
    local ns_id = 123

    before_each(function()
        -- Reset modules
        package.loaded["bookmarks.extmark"] = nil

        -- Setup mocks
        mock.setup_vim_api()

        -- Stub Neovim extmark APIs
        stub(vim.api, "nvim_create_namespace").returns(ns_id)
        stub(vim.api, "nvim_buf_set_extmark").returns(1000)
        stub(vim.api, "nvim_buf_del_extmark")
        stub(vim.api, "nvim_buf_get_extmark_by_id").returns({ 9, 0 }) -- line 10, col 0
        stub(vim.api, "nvim_buf_clear_namespace")

        -- Load module
        extmark = require("bookmarks.extmark")
    end)

    after_each(function()
        mock.teardown()
    end)

    describe("add", function()
        it("should create extmark at specified position", function()
            local bufnr = 1
            local lnum = 10

            local id = extmark.add(bufnr, lnum)

            assert.are.equal(1000, id)
            assert.stub(vim.api.nvim_buf_set_extmark).was_called_with(bufnr, ns_id, 9, 0, {})
        end)
    end)

    describe("delete", function()
        it("should remove extmark by id", function()
            local bufnr = 1
            local id = 1000

            extmark.delete(bufnr, id)

            assert.stub(vim.api.nvim_buf_del_extmark).was_called_with(bufnr, ns_id, id)
        end)
    end)

    describe("clear_all", function()
        it("should clear entire namespace for buffer", function()
            local bufnr = 1
            extmark.clear_all(bufnr)

            assert.stub(vim.api.nvim_buf_clear_namespace).was_called_with(bufnr, ns_id, 0, -1)
        end)
    end)

    describe("get_lnum", function()
        it("should return 1-indexed line number for extmark id", function()
            local bufnr = 1
            local id = 1000

            local lnum = extmark.get_lnum(bufnr, id)

            assert.are.equal(10, lnum)
            assert.stub(vim.api.nvim_buf_get_extmark_by_id).was_called_with(bufnr, ns_id, id, {})
        end)

        it("should return nil if extmark not found", function()
            vim.api.nvim_buf_get_extmark_by_id:returns({})

            local lnum = extmark.get_lnum(1, 999)

            assert.is_nil(lnum)
        end)
    end)
end)
