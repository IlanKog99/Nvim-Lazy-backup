-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Ctrl+E = move to end of line
map("n", "<C-e>", "$", opts) -- Normal mode
map("i", "<C-e>", "<Esc>A", opts) -- insert mode

-- Ctrl+A = move to start of line
map("n", "<C-a>", "^", opts) -- Normal mode
map("i", "<C-a>", "<Esc>I", opts) -- Insert mode

-- CTRL + Z = Undo
map("n", "<C-z>", "u", opts) -- Normal mode
map("v", "<C-z>", "u", opts) -- View mode
map("i", "<C-z>", "<Esc>ui", opts) -- Insert mode

-- CTRL + Arrow = Navigate words
map("n", "<C-Right>", "w", opts) -- Normal mode
map("i", "<C-Right>", "<Esc>wi", opts) -- Insert mode
map("n", "<C-Left>", "b", opts) -- Normal mode
map("i", "<C-Left>", "<Esc>bi", opts) -- Insert mode

