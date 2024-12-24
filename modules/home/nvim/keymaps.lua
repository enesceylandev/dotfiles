-- Leader keys
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Disable spacebar's default behavior in normal and visual modes
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

local opts = { noremap = true, silent = true }

-- File operations
vim.keymap.set('n', '<C-s>', '<cmd>w<CR>', opts) -- Save
vim.keymap.set('n', '<leader>sn', '<cmd>q<CR>', opts) -- Quit

-- Text manipulation
vim.keymap.set('n', 'x', '"_x', opts) -- Delete without yanking
vim.keymap.set('v', 'p', '"_dP', opts) -- Paste while keeping last yanked

-- Search and center
vim.keymap.set('n', 'n', 'Nzzzv', opts)
vim.keymap.set('n', 'N', 'nzzzv', opts)

-- Buffer navigation
vim.keymap.set('n', '<Tab>', ':bnext<CR>', opts) -- Next buffer
vim.keymap.set('n', '<S-Tab>', ':bprevious<CR>', opts) -- Previous buffer
vim.keymap.set('n', '<C-w>', ':Bdelete!<CR>', opts) -- Close buffer

-- Split windows
vim.keymap.set('n', '<leader>sv', '<C-w>v', { noremap = true, silent = true, desc = '[S]plit vertical' }) -- Vertical split
vim.keymap.set('n', '<leader>sh', '<C-w>s', { noremap = true, silent = true, desc = '[S]plit horizontal' }) -- Horizontal split
-- vim.keymap.set('n', '<leader>se', '<C-w>=', { noremap = true, silent = true, desc = '[S]plit Equlizer' })    -- Equalize splits
vim.keymap.set('n', '<leader>w', ':close<CR>', { noremap = true, silent = true, desc = 'Close the window' }) -- Close window

-- Window navigation
vim.keymap.set('n', '<C-Up>', '<C-w>k', opts) -- Move to the upper split
vim.keymap.set('n', '<C-Down>', '<C-w>j', opts) -- Move to the lower split
vim.keymap.set('n', '<C-Left>', '<C-w>h', opts) -- Move to the left split
vim.keymap.set('n', '<C-Right>', '<C-w>l', opts) -- Move to the right split

-- Stay in indent mode in visual mode
vim.keymap.set('v', '<', '<gv', opts)
vim.keymap.set('v', '>', '>gv', opts)

-- Diagnostic keymaps
-- vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
-- vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
-- vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
-- vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- Insert mode enhancements
vim.keymap.set('i', '<C-H>', '<C-w>', { desc = 'Delete word backward in insert mode' })
vim.keymap.set('i', '<C-Enter>', '<Esc>o', { desc = 'Insert newline below and return to insert mode' })
vim.keymap.set('i', '<C-v>', '<Esc>"+pa', opts) -- Paste from system clipboard
vim.keymap.set('i', '<C-z>', '<cmd>u<CR>', opts) -- Undo in insert mode
vim.keymap.set('i', '<C-BS>', '<C-w>', { desc = 'Delete word backward in insert mode' })
vim.keymap.set('i', '<C-s>', '<cmd>w<CR>', { desc = 'Save changes in insert mode' })

-- Normal mode enhancements
vim.keymap.set('n', '<C-z>', '<cmd>undo<CR>', opts) -- Undo
vim.keymap.set('n', '<C-w>', '<cmd>bd<CR>', opts) -- Close buffer
vim.keymap.set('n', '<C-a>', 'ggVG', { desc = 'Select all content' }) -- Select all
vim.keymap.set('n', 'j', [[v:count?'j':'gj']], { noremap = true, expr = true, desc = 'Move cursor down' })
vim.keymap.set('n', 'k', [[v:count?'k':'gk']], { noremap = true, expr = true, desc = 'Move cursor up' })
vim.keymap.set('n', '<leader>nh', ':nohl<CR>', { noremap = true, silent = true, desc = 'Clear search highlights' })
vim.keymap.set('n', '<Esc>', ':noh<CR><Esc>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>nd', '<cmd>NoiceDismiss<CR>', { desc = 'Dismiss Noice notifications' })
vim.keymap.set('n', '<S-Up>', '{', { noremap = true, silent = true })
vim.keymap.set('n', '<S-Down>', '}', { noremap = true, silent = true })
vim.keymap.set('n', 'd<S-Up>', 'd{', { noremap = true, silent = true })
vim.keymap.set('n', 'd<S-Down>', 'd}', { noremap = true, silent = true })

-- Quick navigation within file
vim.keymap.set('n', '<leader><Up>', '0k', opts) -- Move to the beginning of the previous line
vim.keymap.set('n', '<leader><Down>', '0j', opts) -- Move to the beginning of the next line

-- Move lines
vim.keymap.set('n', '<A-Up>', ':m .-2<CR>==', opts) -- Move current line up
vim.keymap.set('n', '<A-Down>', ':m .+1<CR>==', opts) -- Move current line down

-- Search and replace shortcuts
vim.api.nvim_set_keymap('n', '<C-g>', ':s/', { noremap = true }) -- Search and replace
vim.api.nvim_set_keymap('v', '<C-g>', ':s/', { noremap = true }) -- Search and replace
vim.api.nvim_set_keymap('n', '<C-f>', '/', { noremap = true }) -- Search
vim.api.nvim_set_keymap('n', '<C-d>', '#', { noremap = true, silent = true }) -- Find previous occurrence

-- Terminal toggles and movement
vim.api.nvim_set_keymap('n', '<C-Esc>', ':ToggleTerm<CR>', opts) -- Toggle terminal
vim.api.nvim_set_keymap('t', '<C-Esc>', '<Cmd>ToggleTerm<CR>', opts)
vim.api.nvim_set_keymap('t', '<C-Up>', '<Cmd>wincmd k<CR>', opts) -- Move terminal focus up
vim.api.nvim_set_keymap('t', '<C-Down>', '<Cmd>wincmd j<CR>', opts) -- Move terminal focus down

-- Moving between buffers
vim.api.nvim_set_keymap('n', '<A-Right>', ':bnext<CR>', opts)
vim.api.nvim_set_keymap('n', '<A-Left>', ':bprev<CR>', opts)

-- Visual mode move lines
vim.keymap.set('v', '<A-Up>', ":m '<-2<CR>gv=gv", opts)
vim.keymap.set('v', '<A-Down>', ":m '>+1<CR>gv=gv", opts)

-- Visual mode quick navigation
vim.keymap.set('v', '<leader><Up>', '0k', opts)
vim.keymap.set('v', '<leader><Down>', '0j', opts)

-- Visual mode bracket navigation
vim.api.nvim_set_keymap('v', '<S-Up>', '{', opts)
vim.api.nvim_set_keymap('v', '<S-Down>', '}', opts)
vim.api.nvim_set_keymap('v', 'd<S-Up>', 'd{', opts)
vim.api.nvim_set_keymap('v', 'd<S-Down>', 'd}', opts)
