# bookmarks.lua

## Installation

### lazy.nvim

```lua
return {
    "kdnk/bookmarks.lua",
    config = function()
        require("bookmarks").setup({
            persist = true,
            serialize_path = "./.Bookmarks.json",
            sign = {
                group = "Bookmark",
                name = "Bookmark",
            },
        })

        vim.keymap.set("n", "mm", require("bookmarks").toggle)
        vim.keymap.set("n", "<C-,>", require("bookmarks").jump_prev)
        vim.keymap.set("n", "<C-.>", require("bookmarks").jump_next)
        vim.keymap.set("n", "mx", require("bookmarks").reset)

        local bookmarkGroup = vim.api.nvim_create_augroup("bookmark_auto_restore", {})
        vim.api.nvim_create_autocmd("VimLeave", {
            callback = function()
                require("bookmarks.sync").write()
            end,
            group = bookmarkGroup,
        })
        vim.api.nvim_create_autocmd({ "VimEnter", "SessionLoadPost" }, {
            callback = function()
                require("bookmarks.sync").read()
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

- https://github.com/niuiic/core.nvim
  - Most of utility functions come from the repository.
- https://github.com/MattesGroeger/vim-bookmarks 
