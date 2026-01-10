-- Minimal init file for testing
-- This file sets up the minimal environment needed to run tests

-- Get plenary path from environment or default location
local plenary_dir = os.getenv("PLENARY_DIR") or vim.fn.stdpath("data") .. "/lazy/plenary.nvim"

-- Get plugin directory (current working directory)
local plugin_dir = vim.fn.getcwd()

-- Add plenary and plugin to runtimepath
vim.opt.rtp:append(plenary_dir)
vim.opt.rtp:append(plugin_dir)

-- Load plenary
vim.cmd("runtime! plugin/plenary.vim")

-- Minimal settings for testing
vim.opt.swapfile = false
vim.opt.termguicolors = true

-- Ensure tests can find the bookmarks module
package.path = package.path .. ";" .. plugin_dir .. "/lua/?.lua;" .. plugin_dir .. "/lua/?/init.lua"
