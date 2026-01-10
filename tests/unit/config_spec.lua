-- Tests for bookmarks/config.lua

local stub = require("luassert.stub")

describe("config", function()
    local config

    before_each(function()
        -- Reset modules
        package.loaded["bookmarks.config"] = nil
        package.loaded["bookmarks.core"] = nil

        -- Stub vim functions
        stub(vim.fn, "sign_define")
        stub(vim.api, "nvim_echo")

        -- Load module
        config = require("bookmarks.config")
    end)

    after_each(function()
        -- No cleanup needed
    end)

    describe("setup", function()
        it("should initialize with default config", function()
            config.setup()

            assert.is_not_nil(config.persist)
            assert.is_true(config.persist.enable)
            assert.is_true(config.persist.per_branch)
        end)

        it("should merge user config with defaults", function()
            config.setup({
                persist = {
                    enable = false,
                },
            })

            assert.is_false(config.persist.enable)
            assert.is_true(config.persist.per_branch) -- Default preserved
        end)

        it("should define bookmark sign", function()
            config.setup()

            assert.stub(vim.fn.sign_define).was_called()
            assert.stub(vim.fn.sign_define).was_called_with(
                "Bookmark",
                {
                    text = "⚑",
                    texthl = "BookmarkSignText",
                    linehl = "BookmarkSignLine",
                }
            )
        end)

        it("should use custom sign text", function()
            config.setup({
                sign = {
                    text = "🔖",
                },
            })

            assert.stub(vim.fn.sign_define).was_called_with(
                "Bookmark",
                {
                    text = "🔖",
                    texthl = "BookmarkSignText",
                    linehl = "BookmarkSignLine",
                }
            )
        end)

        it("should warn on deprecated persist.dir", function()
            config.setup({
                persist = {
                    dir = "/old/path",
                },
            })

            assert.stub(vim.api.nvim_echo).was_called()
        end)

        it("should have scrollbar config", function()
            config.setup()

            assert.is_not_nil(config.scrollbar)
            assert.is_false(config.scrollbar.enable)
            assert.are.equal("⚑", config.scrollbar.text)
        end)
    end)

    describe("default values", function()
        it("should have persist enabled by default", function()
            config.setup()

            assert.is_true(config.persist.enable)
        end)

        it("should have per_branch enabled by default", function()
            config.setup()

            assert.is_true(config.persist.per_branch)
        end)

        it("should have scrollbar disabled by default", function()
            config.setup()

            assert.is_false(config.scrollbar.enable)
        end)
    end)
end)
