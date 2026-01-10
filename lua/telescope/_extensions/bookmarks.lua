local telescope = require("telescope")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local entry_display = require("telescope.pickers.entry_display")
local conf = require("telescope.config").values

local bookmark = require("bookmarks.bookmark")

---@param bufnr integer
local function get_relative_path(bufnr)
    return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":~:.")
end

local function bookmark_picker(opts)
    opts = opts or {}

    bookmark.update_bufnr()
    local bs = bookmark.list()

    ---@type { filename: string, lnum: number, bufnr: integer, index: integer }[]
    local marklist = {}
    for i, b in ipairs(bs) do
        table.insert(marklist, {
            filename = b.filename,
            lnum = b.lnum,
            bufnr = b.bufnr,
            index = i,
        })
    end

    local display = function(entry)
        local displayer = entry_display.create({
            separator = " ",
            items = {
                { width = 10 },
                { remaining = true },
            },
        })

        return displayer({
            { entry.value.index, "TelescopeResultsLineNr" },
            get_relative_path(entry.value.bufnr) .. ":" .. entry.value.lnum,
        })
    end

    pickers
        .new(opts, {
            prompt_title = "nvim-bookmarks",
            finder = finders.new_table({
                results = marklist,
                entry_maker = function(entry)
                    return {
                        valid = true,
                        value = entry,
                        display = display,
                        ordinal = entry.filename .. " " .. entry.lnum,
                        filename = entry.filename,
                        lnum = entry.lnum,
                        col = 1,
                    }
                end,
            }),
            sorter = conf.generic_sorter(opts),
            previewer = conf.qflist_previewer(opts),
        })
        :find()
end

return telescope.register_extension({ exports = { list = bookmark_picker } })
