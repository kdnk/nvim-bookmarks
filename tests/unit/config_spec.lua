-- Tests for bookmarks/config.lua

local stub = require("luassert.stub")
local match = require("luassert.match")

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

        describe("validation", function()

            before_each(function()

                -- Mock vim.notify to catch warnings

                stub(vim, "notify")

            end)

    

            after_each(function()

                vim.notify:revert()

            end)

    

            it("should accept valid config", function()

                local opts = {

                    persist = { enable = false },

                    sign = { text = "B" }

                }

                config.setup(opts)

                

                assert.is_false(config.persist.enable)

                assert.are.equal("B", config.sign.text)

                assert.stub(vim.notify).was_not_called()

            end)

    

                    it("should warn and use default on invalid boolean type", function()

    

                        local opts = {

    

                            persist = { enable = "true" } -- Invalid: string instead of boolean

    

                        }

    

                        config.setup(opts)

    

                        

    

                        assert.is_true(config.persist.enable) -- Should fallback to default true

    

                        assert.stub(vim.notify).was_called_with(

    

                            match.matches("%[nvim%-bookmarks%] .*must be a boolean"),

    

                            vim.log.levels.WARN,

    

                            nil

    

                        )

    

                    end)

    

            

    

                    it("should warn and use default on invalid string type", function()

    

                        local opts = {

    

                            sign = { text = 123 } -- Invalid: number instead of string

    

                        }

    

                        config.setup(opts)

    

                        

    

                        assert.are.equal("⚑", config.sign.text) -- Should fallback to default

    

                        assert.stub(vim.notify).was_called_with(

    

                            match.matches("%[nvim%-bookmarks%] .*must be a string"),

    

                            vim.log.levels.WARN,

    

                            nil

    

                        )

    

                    end)

        end)

    end)
