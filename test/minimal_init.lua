-- Minimal init for running tests
vim.opt.rtp:prepend('.')

-- Disable unnecessary plugins
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Basic vim settings for tests
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.hidden = true
