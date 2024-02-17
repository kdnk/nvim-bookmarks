# bookmarks-cycle-through.nvim

This plugin adds a feature to move across buffers to [MattesGroeger/vim-bookmarks](https://github.com/MattesGroeger/vim-bookmarks).

## Installation

```
{
  "kdnk/bookmarks-cycle-through.nvim",
  dependencies = {
      "MattesGroeger/vim-bookmarks",
  },
}
```

## Configuration

```lua
vim.keymap.set("n", "mm", require("bookmarks-cycle-through").toggle_bookmark)
vim.keymap.set("n", "]b", function()
    require("bookmarks-cycle-through").cycle_through(false)
end)
vim.keymap.set("n", "[b", function()
    require("bookmarks-cycle-through").cycle_through(true)
end)
```

## Integration

### lualine

```lua
local function bookmark_count()
    return string.format([[📘 %s]], require("bookmarks-cycle-through").bookmark_count_or_index())

    require("lualine").setup({
        sections = {
            lualine_c = {
                { bookmark_count },
            },
        },
    })
end
```
