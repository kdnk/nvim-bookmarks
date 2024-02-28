# Table of Contents

- [Table of Contents](#table-of-contents)
- [Installation & Configuration](#installation--configuration)
  - [lazy.nvim](#lazynvim)
- [Integration](#integration)
  - [lualine](#lualine)
  - [Telescope](#telescope)
  - [Thanks & Inspired](#thanks--inspired)

    -   [lualine](#lualine)
    -   [Telescope](#telescope)
    -   [Thanks & Inspired](#thanks--inspired)

        -   [lualine](#lualine)
        -   [Telescope](#telescope)
        -   [Thanks & Inspired](#thanks--inspired)

-   [Table of Contents](#table-of-contents)
-   [Installation & Configuration](#installation--configuration)
    -   [lazy.nvim](#lazynvim)
-   [Integration](#integration)
    -   [lualine](#lualine)
    -   [Telescope](#telescope)
    -   [Thanks & Inspired](#thanks--inspired)

# Installation & Configuration

## lazy.nvim

```lua
return {
    "kdnk/bookmarks.lua",
    config = function()
        local bm = require("bookmarks")

        bm.setup({
            persist = {
                enable = true,
                path = "./.bookmarks", -- .bookmarks.json will be created.
                per_branch = false,  -- store backup per branch.
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
vim.keymap.set("n", "<leader>b", function() require("telescope").extensions.bookmarks.list() end, { silent = true })
```

## Thanks & Inspired

-   https://github.com/niuiic/core.nvim
    -   Most of utility functions come from the repository.
-   https://github.com/MattesGroeger/vim-bookmarks
