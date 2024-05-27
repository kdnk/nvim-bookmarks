# Table of Contents

-   [Table of Contents](#table-of-contents)
-   [Installation](#installation)
    -   [lazy.nvim](#lazynvim)
-   [Configuration](#configuration)
-   [Integration](#integration)
    -   [lualine](#lualine)
    -   [Telescope](#telescope)
-   [Credit](#credit)

# Installation

## [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
    "kdnk/nvim-bookmarks",
}
```

# Configuration

```lua
return {
    "kdnk/nvim-bookmarks",
    config = function()
        local bm = require("bookmarks")

        bm.setup({
            persist = {
                enable = true,
                dir = "./.bookmarks", -- directory to store json file for backup. Please add `**/.bookmarks/*` to your `.gitignore_global`.
                per_branch = true, -- store backup file for each branch
            },
            sign = {
                text = "⚑",
            },
        })

        vim.keymap.set("n", "mm", bm.toggle) -- toggle bookmark at current line
        vim.keymap.set("n", "<C-,>", bm.jump_prev) -- jump to the previous bookmark over buffers
        vim.keymap.set("n", "<C-.>", bm.jump_next) -- jump to the next bookmark over buffers
        vim.keymap.set("n", "mx", bm.reset) -- remove all bookmarks
        vim.keymap.set("n", "mr", bm.restore) -- restore bookmarks from the json backup file

        -- autocmd to restore bookmarks from the json backup file
        local bookmarkGroup = vim.api.nvim_create_augroup("bookmark_auto_restore", {})
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

# Credit

-   https://github.com/niuiic/core.nvim
-   https://github.com/MattesGroeger/vim-bookmarks
