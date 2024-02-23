# bookmarks.lua

## Installation

### lazy.nvim

```lua
{
  "kdnk/bookmarks.lua",
}
```

## Configuration

```lua
vim.keymap.set("n", "mm", require("bookmarks").toggle)
vim.keymap.set("n", "<C-,>", require("bookmarks").jump_prev)
vim.keymap.set("n", "<C-.>", require("bookmarks").jump_next)
vim.keymap.set("n", "mx", require("bookmarks").reset)
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
