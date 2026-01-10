---@meta

---@class Bookmarks.Config
---@field persist { enable: boolean, per_branch: boolean }
---@field sign { group: string, name: string, text: string }
---@field scrollbar { enable: boolean, text: string }

---@class Bookmarks.Bookmark
---@field id string Unique identifier for the bookmark
---@field filename string Absolute path to the file
---@field bufnr integer Buffer handle (may be -1 if not loaded)
---@field lnum number 1-indexed line number
---@field extmark_id integer|nil Neovim extmark ID for position tracking

---@class Bookmarks.Sign
---@field id integer
---@field group string
---@field name string
---@field priority number
---@field bufnr integer
---@field lnum number

---@class Bookmarks.Service
---@field setup fun(opts?: Bookmarks.Config)
---@field toggle fun()
---@field add fun(bufnr: integer, lnum: number)
---@field delete fun(bufnr: integer, lnum: number)
---@field jump_next fun()
---@field jump_prev fun()
---@field reset fun()
