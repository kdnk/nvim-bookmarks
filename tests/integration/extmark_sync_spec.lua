-- Integration tests for extmark synchronization and persistence

local mock = require("tests.helpers.mock")
local stub = require("luassert.stub")

describe("extmark sync (integration)", function()
    local bm
    local bookmark
    local extmark
    local persist
    local config
    local sync

    local test_data_dir = "/tmp/test_data"
    local test_cwd = vim.fn.getcwd()
    local test_hash_full = vim.fn.sha256(test_cwd)
    local test_hash = test_hash_full:sub(1, 16)
    local expected_path = test_data_dir .. "/nvim-bookmarks/" .. test_hash .. "/main.json"

    before_each(function()
        -- WORKAROUND: Ensure package.path includes project lua directory
        local cwd = vim.fn.getcwd()
        if not string.find(package.path, cwd .. "/lua/%%?.lua") then
            package.path = package.path .. ";" .. cwd .. "/lua/?.lua;" .. cwd .. "/lua/?/init.lua"
        end

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
        mock.setup_git()

        -- Stub environment-specific functions
        stub(vim.fn, "stdpath").returns(test_data_dir)
        stub(vim.fn, "mkdir")

        -- Stub sign/extmark functions
        stub(vim.fn, "sign_place")
        stub(vim.fn, "sign_unplace")
        stub(vim.fn, "sign_getplaced").returns({ { signs = {} } })
        stub(vim.fn, "sign_define")
        
        -- Stub extmark APIs with state to simulate movement
        local extmarks = {}
        stub(vim.api, "nvim_create_namespace").returns(1)
        stub(vim.api, "nvim_buf_set_extmark").invokes(function(bufnr, ns, line, col, opts)
            local id = opts.id or (#extmarks + 1)
            extmarks[id] = { line = line, col = col, bufnr = bufnr }
            return id
        end)
        stub(vim.api, "nvim_buf_del_extmark")
        stub(vim.api, "nvim_buf_get_extmarks").returns({})
        
        -- Stub bufadd/bufnr
        stub(vim.fn, "bufadd").invokes(function(filename) return 1 end)
        stub(vim.fn, "bufnr").returns(1)

        -- Mock file module validation
        local file = require("bookmarks.file")
        file.get_max_lnum = function(filename)
            return 1000
        end

        -- Load modules
        config = require("bookmarks.config")
        bm = require("bookmarks.init")
        bookmark = require("bookmarks.bookmark")
        persist = require("bookmarks.persist")
        extmark = require("bookmarks.extmark")
        sync = require("bookmarks.sync")
        
        -- Setup plugin
        config.setup()
        bm.setup()
    end)

    after_each(function()
        bookmark.remove_all()
        mock.teardown()
    end)

    it("should save updated bookmark position when extmark moves", function()
        local bufnr = 1
        local original_lnum = 10
        local new_lnum = 11
        mock.set_buf_name(bufnr, "/test/file.lua")

        -- 1. Add a bookmark
        bookmark.add(bufnr, original_lnum)
        
        -- Verify initial save
        local initial_write = mock.get_written_file(expected_path)
        assert.is_not_nil(initial_write)
        local initial_json = vim.json.decode(initial_write[1])
        assert.are.equal(original_lnum, initial_json[1].lnum)

        -- Clear written files to verify next write
        mock.reset() 
        -- Note: mock.reset clears written files but keeps other mocks active if using helper's reset.
        -- But here we need to keep stubs active. Helper's reset might clear stubs.
        -- Let's just clear the written files map manually or check if it changed.
        -- Helper's reset() does NOT clear stubs, only state. Perfect.
        mock.reset() 
        
        -- 2. Simulate extmark movement
        -- We mock extmark.get_position_changes to return a change
        -- In reality, nvim triggers TextChanged, which calls sync.extmarks_to_bookmarks, 
        -- which calls get_position_changes.
        
        -- We stub get_position_changes to simulate that nvim reported a move
        local extmark_mod = require("bookmarks.extmark")
        stub(extmark_mod, "get_position_changes").returns({ [original_lnum] = new_lnum })

        -- 3. Trigger the sync (simulating TextChanged event)
        sync.extmarks_to_bookmarks(bufnr)

        -- 4. Verify persist.backup was called and file was updated
        local updated_write = mock.get_written_file(expected_path)
        assert.is_not_nil(updated_write, "persist.backup should have been called")
        
        local updated_json = vim.json.decode(updated_write[1])
        assert.are.equal(new_lnum, updated_json[1].lnum, "Bookmark line number should be updated in JSON")
    end)
end)
