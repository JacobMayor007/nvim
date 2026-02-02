-- Save with Ctrl + S in Normal mode
vim.keymap.set('n', '<C-s>', ':w<CR>', { silent = true })

-- Save with Ctrl + S in Insert mode
vim.keymap.set('i', '<C-s>', '<Esc>:w<CR>gi', { silent = true })

-- Enable line numbers (helpful for coding!)
vim.opt.number = true

-- Enable mouse support (lets you click and scroll)
vim.opt.mouse = 'a'
