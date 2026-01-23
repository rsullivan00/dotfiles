-- Custom keymaps to match old nvim config

local map = vim.keymap.set

-- Ctrl+P for fuzzy file search (like old fzf config)
-- Uses LazyVim's picker (works with Telescope, fzf-lua, or snacks.picker)
map("n", "<C-p>", function()
  Snacks.picker.files()
end, { desc = "Find Files (Ctrl+P)" })

-- 0 goes to first non-blank character instead of line start
map("n", "0", "^", { desc = "Go to first non-blank character" })

-- Clear search highlighting with double Escape
map("n", "<Esc><Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
map("n", "<C-c><C-c>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Command typo aliases
vim.api.nvim_create_user_command("W", "w", {})
vim.api.nvim_create_user_command("Q", "q", {})
vim.api.nvim_create_user_command("Wq", "wq", {})
vim.api.nvim_create_user_command("Qa", "qa", {})
