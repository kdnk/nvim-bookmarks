vim.g.bookmark_sign_group = "bookmark"
vim.g.bookmark_sign_name = "Bookmark"
vim.g.bookmark_serialize_path = "./.bookmarks.json"

---@class Sign
---@field group string
---@field id integer
---@field lnum number
---@field bufnr integer
---@field name string
---@field priority number

vim.fn.sign_define("Bookmark", { text = "⚑" })
