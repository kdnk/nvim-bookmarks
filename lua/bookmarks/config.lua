local M = {}

---@type Bookmarks.Config
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

---@param user_conf table
---@return Bookmarks.Config
local function validate_config(user_conf)
    local conf = vim.deepcopy(default_config)
    
    if not user_conf then return conf end

    -- Helper to validate and merge a single field
    local function check(path, key, type_str)
        local val = user_conf
        for _, p in ipairs(path) do
            if type(val) ~= "table" then return end
            val = val[p]
        end
        
        if val == nil then return end
        
        if type(val) == type_str then
            -- Navigate and set
            local target = conf
            for i = 1, #path - 1 do
                target = target[path[i]]
            end
            target[path[#path]] = val
        else
            vim.notify(string.format(
                "[nvim-bookmarks] Config error: '%s' must be a %s. Using default.",
                table.concat(path, "."), type_str
            ), vim.log.levels.WARN)
        end
    end

    -- Validate fields
    if user_conf.persist then
        check({ "persist", "enable" }, "enable", "boolean")
        check({ "persist", "per_branch" }, "per_branch", "boolean")
    end
    
    if user_conf.sign then
        check({ "sign", "text" }, "text", "string")
        check({ "sign", "group" }, "group", "string")
        check({ "sign", "name" }, "name", "string")
    end

    if user_conf.scrollbar then
        check({ "scrollbar", "enable" }, "enable", "boolean")
        check({ "scrollbar", "text" }, "text", "string")
    end

    return conf
end

---@param opts? Bookmarks.Config
function M.setup(opts)
    local new_conf = validate_config(opts)

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
