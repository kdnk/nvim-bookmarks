local core = require("bookmarks.core")
local M = {}

local default_config = {
    persist = {
        enable = true,
        dir = "./.bookmarks",
        per_branch = true,
    },
    scrollbar = {
        enable = false,
        text = "⚑",
    },
    sign = {
        group = "Bookmark",
        name = "Bookmark",
        text = "⚑",
    },
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@alias Config { persist: { enable: boolean, dir: string, per_branch: boolean }, serialize_path: string, sign: { group: string, name: string, text: string } }

---@param opts? Config
function M.setup(opts)
    local new_conf = vim.tbl_deep_extend("keep", opts or {}, default_config)

    core.lua.table.each(new_conf, function(k, v)
        M[k] = v
    end)

    vim.fn.sign_define(
        "Bookmark",
        { text = new_conf.sign.text, texthl = "BookmarkSignText", linehl = "BookmarkSignLine" }
    )
end

return M
