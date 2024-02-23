local core = require("bookmarks.core")
local M = {}

local default_config = {
    persist = false,
    serialize_path = "./.Bookmarks.json",
    sign = {
        group = "Bookmark",
        name = "Bookmark",
    },
}

---@param opts? { persist: boolean, serialize_path: string, sign: { group: string, name: string } }
function M.setup(opts)
    local new_conf = vim.tbl_deep_extend("keep", opts or {}, default_config)

    core.table.each(new_conf, function(k, v)
        M[k] = v
    end)
end

return M
