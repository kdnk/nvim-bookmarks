---@class Sign
---@field group string
---@field id integer
---@field lnum number
---@field bufnr integer
---@field name string
---@field priority number

vim.fn.sign_define("Bookmark", { text = "⚑" })
