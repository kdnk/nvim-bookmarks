local bookmark = require("bookmarks.bookmark")
local config = require("bookmarks.config")
local file = require("bookmarks.file")
local sync = require("bookmarks.sync")

local M = {}

local function persist_path()
    local branch = vim.fn.systemlist("git branch --show-current")[1] or ""
    if config.persist.per_branch then
        return config.persist.dir .. "/" .. branch .. ".json"
    else
        return config.persist.dir .. "/" .. "bookmarks.json"
    end
end

function M.backup()
    if config.persist.enable then
        bookmark.update_bufnr()
        local json = bookmark.toJson()
        file.json_write(json, persist_path())
    end
end

function M.restore()
    if not config.persist.enable then
        return {}
    end

    if not file.exists(config.persist.dir) then
        vim.api.nvim_echo({ { "config.persist.dir is not configured.", "WarningMsg" } }, true, {})
        return {}
    end

    vim.schedule(function()
        local json = file.json_read(persist_path())
        local bookmarks = bookmark.fromJson(json)
        bookmark.update_all(bookmarks)

        sync.bookmarks_to_signs()
    end)
end

return M
