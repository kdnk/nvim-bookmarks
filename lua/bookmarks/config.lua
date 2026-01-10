local M = {}

local default_config = {
    persist = {
        enable = true,
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
---@alias Config { persist: { enable: boolean, per_branch: boolean }, serialize_path: string, sign: { group: string, name: string, text: string } }

---@param opts? Config
function M.setup(opts)
    local new_conf = vim.tbl_deep_extend("keep", opts or {}, default_config)

    -- Warn if user is using deprecated persist.dir setting
    if opts and opts.persist and opts.persist.dir then
        local data_dir = vim.fn.stdpath("data")
        vim.api.nvim_echo({
            { "[nvim-bookmarks] WARNING: ", "WarningMsg" },
            { "config.persist.dir is deprecated and will be ignored.\n", "Normal" },
            { "Bookmarks are now stored in: ", "Normal" },
            { data_dir .. "/nvim-bookmarks/", "String" },
        }, true, {})
    end

    for k, v in pairs(new_conf) do
        M[k] = v
    end

    vim.fn.sign_define(
        "Bookmark",
        { text = new_conf.sign.text, texthl = "BookmarkSignText", linehl = "BookmarkSignLine" }
    )
end

return M
