# bookmarks.lua

## Installation & Configuration

### lazy.nvim

```lua
return {
    "kdnk/bookmarks.lua",
    config = function()
        local bm = require("bookmarks")
        local persist = require("bookmarks.persist")

        bm.setup({
            persist = {
                enable = true,
                path = "./.bookmarks.json",
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

        local bookmarkGroup = vim.api.nvim_create_augroup("bookmark_auto_restore", {})
        vim.api.nvim_create_autocmd("VimLeave", {
            callback = function()
                persist.write()
            end,
            group = bookmarkGroup,
        })
        vim.api.nvim_create_autocmd({ "VimEnter", "SessionLoadPost" }, {
            callback = function()
                persist.read()
            end,
            group = bookmarkGroup,
        })
    end,
}
```

## Integration

### lualine

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

## Thanks & Inspired

-   https://github.com/niuiic/core.nvim
    -   Most of utility functions come from the repository.
-   https://github.com/MattesGroeger/vim-bookmarks
