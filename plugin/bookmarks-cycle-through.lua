vim.g.bookmark_sign_group = ""
vim.g.bookmark_sign_name = "Bookmark"

---@class Sign
---@field group string
---@field id integer
---@field lnum number
---@field bufnr integer
---@field name string
---@field priority number

---@class Bookmark
---@field bufnr number
---@field lnum number

---@type Bookmark[]
vim.g.bookmarks = {}

vim.fn.sign_define("Bookmark", { text = "⚑" })
