-- Custom options to match old nvim config

local opt = vim.opt

-- Display
opt.colorcolumn = "80"
opt.wrap = false
opt.scrolloff = 4
opt.sidescrolloff = 5

-- Bells
opt.visualbell = true

-- LazyVim already sets these, but being explicit:
-- opt.number = true
-- opt.relativenumber = true
-- opt.cursorline = true
-- opt.ignorecase = true
-- opt.smartcase = true
-- opt.expandtab = true
-- opt.shiftwidth = 2
-- opt.tabstop = 2
-- opt.splitright = true
-- opt.splitbelow = true
-- opt.clipboard = "unnamedplus"
