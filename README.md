# Table of Contents

- [Table of Contents](#table-of-contents)
  - [lazy.nvim](#lazynvim)
- [Integration](#integration)
  - [lualine](#lualine)
  - [Telescope](#telescope)
  - [Credit](#credit)

## lazy.nvim

```lua
return {
    "kdnk/bookmarks.lua",
    config = function()
        local bm = require("bookmarks")

        bm.setup({
            persist = {
                enable = true,
                dir = "./.bookmarks", -- dir to store backup json files for bookmarks
                per_branch = true,  -- store backup per branch.
            },
            sign = {
                group = "Bookmark",
                name = "Bookmark",
                text = "⚑",
            },
        })

        vim.keymap.set("n", "mm", bm.toggle)
        vim.keymap.set("n", "<C-,>", bm.jump_prev)
        vim.keymap.set("n", "<C-.>", bm.jump_next)
        vim.keymap.set("n", "mx", bm.reset)
        vim.keymap.set("n", "mr", bm.restore)

        local bookmarkGroup = vim.api.nvim_create_augroup("bookmark_auto_restore", {})
        vim.api.nvim_create_autocmd("VimLeave", {
            callback = function()
                bm.backup()
            end,
            group = bookmarkGroup,
        })
        vim.api.nvim_create_autocmd({ "VimEnter", "SessionLoadPost" }, {
            callback = function()
                bm.restore()
            end,
            group = bookmarkGroup,
        })
    end,
}
```

# Integration

## lualine

```lua
local function bookmark_count()
    return string.format([[📘 %s]], require("bookmarks.lualine").bookmark_count())
end

require("lualine").setup({
    sections = {
        lualine_c = {
            { bookmark_count },
        },
    },
})
```

## Telescope

```lua
require("telescope").load_extension("bookmarks")
vim.keymap.set("n", "<leader>b", function() require("telescope").extensions.bookmarks.list() end)
```

## Credit

-   https://github.com/niuiic/core.nvim
-   https://github.com/MattesGroeger/vim-bookmarks
