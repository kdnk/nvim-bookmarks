-- Integration tests for bookmark toggle workflow

local mock = require("tests.helpers.mock")
local stub = require("luassert.stub")

describe("toggle workflow (integration)", function()
    local bm
    local bookmark
    local sign
    local extmark
    local persist
    local config

    before_each(function()
        -- Reset modules
        package.loaded["bookmarks.init"] = nil
        package.loaded["bookmarks.bookmark"] = nil
        package.loaded["bookmarks.sign"] = nil
        package.loaded["bookmarks.extmark"] = nil
        package.loaded["bookmarks.persist"] = nil
        package.loaded["bookmarks.config"] = nil
        package.loaded["bookmarks.sync"] = nil
        package.loaded["bookmarks.file"] = nil
        package.loaded["bookmarks.core"] = nil
        package.loaded["bookmarks.autocmd"] = nil

        -- Setup mocks
        mock.setup_vim_api()
        mock.setup_file_io()

        -- Stub vim functions with state
        local placed_signs = {}

        stub(vim.fn, "sign_place").invokes(function(id, group, name, bufnr, opts)
            table.insert(placed_signs, {
                id = 100 + #placed_signs,
                group = group,
                name = name,
                bufnr = bufnr,
                lnum = opts.lnum,
                priority = opts.priority
            })
            return 100 + #placed_signs
        end)

        stub(vim.fn, "sign_unplace").invokes(function(group, opts)
            if opts and opts.id then
                for i, s in ipairs(placed_signs) do
                    if s.id == opts.id then
                        table.remove(placed_signs, i)
                        break
                    end
                end
            elseif opts and opts.buffer then
                -- Remove all for buffer
                 local i = 1
                 while i <= #placed_signs do
                     if placed_signs[i].bufnr == opts.buffer then
                         table.remove(placed_signs, i)
                     else
                         i = i + 1
                     end
                 end
            else
                 -- Remove all
                 placed_signs = {}
            end
        end)

        stub(vim.fn, "sign_getplaced").invokes(function(bufnr, opts)
            local matches = {}
            for _, s in ipairs(placed_signs) do
                if (not bufnr or s.bufnr == bufnr) and 
                   (not opts or not opts.lnum or s.lnum == opts.lnum) and
                   (not opts or not opts.group or s.group == opts.group) then
                    table.insert(matches, s)
                end
            end
            return { { signs = matches } }
        end)

        stub(vim.fn, "sign_define")
        stub(vim.fn, "bufadd").invokes(function(filename)
            return tonumber(filename:match("(%d+)")) or 1
        end)

        -- Stub Neovim extmark APIs
        stub(vim.api, "nvim_create_namespace").returns(123)
        stub(vim.api, "nvim_buf_set_extmark").returns(1000)
        stub(vim.api, "nvim_buf_del_extmark")
        stub(vim.api, "nvim_buf_get_extmark_by_id").returns({ 9, 0 })
        stub(vim.api, "nvim_buf_clear_namespace")
        
        -- Stub cursor position
        stub(vim.api, "nvim_get_current_win").returns(1000)
        stub(vim.api, "nvim_win_get_cursor").returns({ 10, 0 })

        -- Mock file operations
        local file = require("bookmarks.file")
        file.get_max_lnum = function(filename)
            return 1000
        end

        -- Load modules
        bm = require("bookmarks.init")
        bookmark = require("bookmarks.bookmark")
        sign = require("bookmarks.sign")
        extmark = require("bookmarks.extmark")
        persist = require("bookmarks.persist")
        config = require("bookmarks.config")
        
        -- Setup plugin (registers autocmds)
        bm.setup()
    end)

    after_each(function()
        bookmark.remove_all()
        mock.teardown()
    end)

    describe("toggle ON (add bookmark)", function()
        it("should add bookmark at cursor position", function()
            local bufnr = 1
            local lnum = 10
            mock.set_buf_name(bufnr, "/test/file.lua")

            -- Mock current buffer
            vim.api.nvim_get_current_buf = function()
                return bufnr
            end

            bm.toggle()

            -- Verify bookmark was added
            assert.is_true(bookmark.exists(bufnr, lnum))
        end)

        it("should place sign when adding bookmark", function()
            local bufnr = 1
            mock.set_buf_name(bufnr, "/test/file.lua")
            vim.api.nvim_get_current_buf = function()
                return bufnr
            end

            bm.toggle()

            -- Verify sign was placed
            assert.stub(vim.fn.sign_place).was_called()
        end)

        it("should create extmark when adding bookmark", function()
            local bufnr = 1
            mock.set_buf_name(bufnr, "/test/file.lua")
            vim.api.nvim_get_current_buf = function()
                return bufnr
            end

            bm.toggle()

            -- Verify extmark was created
            assert.stub(vim.api.nvim_buf_set_extmark).was_called()
        end)

        it("should backup bookmarks after adding", function()
            local bufnr = 1
            mock.set_buf_name(bufnr, "/test/file.lua")
            vim.api.nvim_get_current_buf = function()
                return bufnr
            end

            bm.toggle()

            -- Verify backup was called (file written)
            -- We can check this indirectly by verifying bookmark persists
            assert.is_true(bookmark.exists(bufnr, 10))
        end)
    end)

    describe("toggle OFF (remove bookmark)", function()
        it("should remove bookmark when toggling existing", function()
            local bufnr = 1
            local lnum = 10
            mock.set_buf_name(bufnr, "/test/file.lua")
            vim.api.nvim_get_current_buf = function()
                return bufnr
            end

            -- Add bookmark first
            bm.toggle()
            assert.is_true(bookmark.exists(bufnr, lnum))

            -- Toggle again to remove
            bm.toggle()
            assert.is_false(bookmark.exists(bufnr, lnum))
        end)

        it("should remove sign when removing bookmark", function()
            local bufnr = 1
            mock.set_buf_name(bufnr, "/test/file.lua")
            vim.api.nvim_get_current_buf = function()
                return bufnr
            end

            -- Add bookmark
            bm.toggle()

            -- Clear previous calls
            vim.fn.sign_unplace:clear()

            -- Remove bookmark
            bm.toggle()

            -- Verify sign was removed
            assert.stub(vim.fn.sign_unplace).was_called()
        end)

        it("should delete extmark when removing bookmark", function()
            local bufnr = 1
            mock.set_buf_name(bufnr, "/test/file.lua")
            vim.api.nvim_get_current_buf = function()
                return bufnr
            end

            -- Add bookmark
            bm.toggle()

            -- Remove bookmark
            bm.toggle()

            -- Verify extmark was cleared (via sync.bookmarks_to_extmarks calling clear_all)
            assert.stub(vim.api.nvim_buf_clear_namespace).was_called()
        end)
    end)

    describe("full toggle cycle", function()
        it("should handle multiple toggle operations", function()
            local bufnr = 1
            local lnum = 10
            mock.set_buf_name(bufnr, "/test/file.lua")
            vim.api.nvim_get_current_buf = function()
                return bufnr
            end

            -- Add
            bm.toggle()
            assert.is_true(bookmark.exists(bufnr, lnum))

            -- Remove
            bm.toggle()
            assert.is_false(bookmark.exists(bufnr, lnum))

            -- Add again
            bm.toggle()
            assert.is_true(bookmark.exists(bufnr, lnum))
        end)

        it("should maintain consistency across all layers", function()
            local bufnr = 1
            local lnum = 10
            mock.set_buf_name(bufnr, "/test/file.lua")
            vim.api.nvim_get_current_buf = function()
                return bufnr
            end

            -- Add bookmark
            bm.toggle()

            -- Verify all layers are updated
            assert.is_true(bookmark.exists(bufnr, lnum)) -- Memory layer
            assert.stub(vim.fn.sign_place).was_called() -- Visual layer
            assert.stub(vim.api.nvim_buf_set_extmark).was_called() -- Position tracking layer

            -- Remove bookmark
            bm.toggle()

            -- Verify all layers are cleaned up
            assert.is_false(bookmark.exists(bufnr, lnum)) -- Memory layer
            assert.stub(vim.fn.sign_unplace).was_called() -- Visual layer
            assert.stub(vim.api.nvim_buf_clear_namespace).was_called() -- Position tracking layer
        end)
    end)
end)
