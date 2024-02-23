local core = require("bookmarks.core")
local M = {}

local default_config = {
    sign = {
        group = "Bookmark",
        name = "Bookmark",
    },
    serialize_path = "./.Bookmarks.json",
}

---@param opts? { sign: { group: string, name: string }, serialize_path: string }
function M.setup(opts)
    local new_conf = vim.tbl_deep_extend("keep", opts or {}, default_config)

    core.table.each(new_conf, function(k, v)
        M[k] = v
    end)
end

return M
