local bookmark = require("bookmarks.bookmark")
local config = require("bookmarks.config")
local file = require("bookmarks.file")
local sync = require("bookmarks.sync")

local M = {}

local function get_project_hash()
    local cwd = vim.fn.getcwd()
    local hash = vim.fn.sha256(cwd)
    return hash:sub(1, 16)
end

local function get_base_dir()
    local data_dir = vim.fn.stdpath("data")
    local project_hash = get_project_hash()
    return data_dir .. "/nvim-bookmarks/" .. project_hash
end

local function sanitize_branch_name(branch)
    -- Replace filesystem-unsafe characters with underscores
    -- This handles: / \ : * ? " < > |
    return branch:gsub("[/\\:*?\"<>|]", "_")
end

local function persist_path()
    local base_dir = get_base_dir()

    if config.persist.per_branch then
        local branch = vim.fn.systemlist("git branch --show-current")[1] or ""
        if branch == "" then
            branch = "default"
        end
        branch = sanitize_branch_name(branch)
        return base_dir .. "/" .. branch .. ".json"
    else
        return base_dir .. "/bookmarks.json"
    end
end

function M.backup()
    if config.persist.enable then
        bookmark.update_bufnr()
        local json = bookmark.to_json()
        file.json_write(json, persist_path())
    end
end

function M.restore()
    if not config.persist.enable then
        return {}
    end

    if not file.exists(persist_path()) then
        return {}
    end

    local json = file.json_read(persist_path())
    local bookmarks = bookmark.from_json(json)
    bookmark.update_all(bookmarks)

    sync.bookmarks_to_signs()

    -- restore時に全てのバッファに対してextmarkを作成
    vim.api.nvim_create_autocmd("BufEnter", {
        once = false,
        callback = function(args)
            local bufnr = args.buf
            if vim.api.nvim_buf_is_loaded(bufnr) then
                sync.bookmarks_to_extmarks(bufnr)
            end
        end,
    })

    if config.scrollbar.enable then
        require("bookmarks.nvim-scrollbar").setup()
    end
end

return M
