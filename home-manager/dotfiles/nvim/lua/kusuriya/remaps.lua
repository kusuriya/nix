vim.g.mapleader = " "
vim.keymap.set("n","<leader>e", vim.cmd.Explore)
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>f', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.git_files, {})
vim.keymap.set('n', '<leader>fp', function()
	builtin.grep_string({search = vim.fn.input("Grep > ")})
end)
vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle)
vim.keymap.set('n', '<leader>gs', vim.cmd.Git)

-- move
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv'")

-- delete
vim.keymap.set("x", "<leader>p", "\"_dP")
