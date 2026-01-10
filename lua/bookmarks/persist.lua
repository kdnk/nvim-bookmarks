local bookmark = require("bookmarks.bookmark")
local config = require("bookmarks.config")
local file = require("bookmarks.file")
local util = require("bookmarks.util")

local M = {}

function M.backup()
    if config.persist.enable then
        local json = bookmark.to_json()
        file.json_write(json, util.get_persist_path(config.persist.per_branch))
    end
end

function M.restore()
    if not config.persist.enable then
        return {}
    end

    local path = util.get_persist_path(config.persist.per_branch)
    if not file.exists(path) then
        return {}
    end

    local json = file.json_read(path)
    local bookmarks = bookmark.from_json(json)
    bookmark.update_all(bookmarks)

    -- 発火させて、autocmd.lua で処理させる
    vim.api.nvim_exec_autocmds("User", { pattern = "BookmarkRestored" })
end

return M
