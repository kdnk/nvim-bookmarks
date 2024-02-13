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
vim.keymap.set("n", "mm", require("bookmarks-cycle-through").mark_toggle)
vim.keymap.set("n", "]b", function()
    require("bookmarks-cycle-through").cycle_through(false)
end)
vim.keymap.set("n", "[b", function()
    require("bookmarks-cycle-through").cycle_through(true)
end)
```
