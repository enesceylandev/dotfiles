-- Leader keys
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local opts = { noremap = true, silent = true }

-- Disable space default behavior
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', opts)

-- File operations
vim.keymap.set('n', '<C-s>', '<cmd>w<CR>', opts) -- Save
vim.keymap.set('n', '<D-s>', '<cmd>w<CR>', opts) -- Save with Command + S
vim.keymap.set('n', '<leader>sn', '<cmd>q<CR>', opts) -- Quit

-- Text manipulation
vim.keymap.set('n', 'x', '"_x', opts)
vim.keymap.set('v', 'p', '"_dP', opts)

-- Search & center
vim.keymap.set('n', 'n', 'Nzzzv', opts)
vim.keymap.set('n', 'N', 'nzzzv', opts)

-- Buffer navigation (Ctrl + Tab is safer than Option)
vim.keymap.set('n', '<C-w>', ':Bdelete!<CR>', opts)

-- Split windows
vim.keymap.set('n', '<leader>sv', '<C-w>v', opts)
vim.keymap.set('n', '<leader>sh', '<C-w>s', opts)
vim.keymap.set('n', '<leader>se', '<C-w>=', opts)
vim.keymap.set('n', '<leader>w', ':close<CR>', opts)

-- Window navigation (Command + Arrow keys for Kitty terminal)
vim.keymap.set('n', '<D-Left>', '<C-w>h', opts)
vim.keymap.set('n', '<D-Down>', '<C-w>j', opts)
vim.keymap.set('n', '<D-Up>', '<C-w>k', opts)
vim.keymap.set('n', '<D-Right>', '<C-w>l', opts)

-- Also keep Space + hjkl as fallback
vim.keymap.set('n', '<leader>h', '<C-w>h', opts)
vim.keymap.set('n', '<leader>j', '<C-w>j', opts)
vim.keymap.set('n', '<leader>k', '<C-w>k', opts)
vim.keymap.set('n', '<leader>l', '<C-w>l', opts)

-- Window resizing (Shift + Command + Arrow keys)
vim.keymap.set('n', '<D-S-Left>', ':vertical resize -5<CR>', opts)
vim.keymap.set('n', '<D-S-Right>', ':vertical resize +5<CR>', opts)
vim.keymap.set('n', '<D-S-Up>', ':resize -5<CR>', opts)
vim.keymap.set('n', '<D-S-Down>', ':resize +5<CR>', opts)

-- Terminal window resizing
vim.keymap.set('t', '<D-S-Left>', '<Cmd>vertical resize -5<CR>', opts)
vim.keymap.set('t', '<D-S-Right>', '<Cmd>vertical resize +5<CR>', opts)
vim.keymap.set('t', '<D-S-Up>', '<Cmd>resize -5<CR>', opts)
vim.keymap.set('t', '<D-S-Down>', '<Cmd>resize +5<CR>', opts)

-- Fallback: Space + arrow keys for resizing
vim.keymap.set('n', '<leader><M-Left>', ':vertical resize -5<CR>', opts)
vim.keymap.set('n', '<leader><M-Right>', ':vertical resize +5<CR>', opts)
vim.keymap.set('n', '<leader><M-Up>', ':resize -5<CR>', opts)
vim.keymap.set('n', '<leader><M-Down>', ':resize +5<CR>', opts)

-- Move lines (Shift + Option + Arrow)
vim.keymap.set('n', '<M-S-Up>', ':m .-2<CR>==', opts)
vim.keymap.set('n', '<M-S-Down>', ':m .+1<CR>==', opts)
vim.keymap.set('v', '<M-S-Up>', ":m '<-2<CR>gv=gv", opts)
vim.keymap.set('v', '<M-S-Down>', ":m '>+1<CR>gv=gv", opts)

-- Jump to blocks with Shift + Up/Down
vim.keymap.set('n', '<S-Up>', '{', opts) -- Jump to opening brace
vim.keymap.set('n', '<S-Down>', '}', opts) -- Jump to closing brace
vim.keymap.set('v', '<S-Up>', '{', opts) -- Jump to opening brace (visual mode)
vim.keymap.set('v', '<S-Down>', '}', opts) -- Jump to closing brace (visual mode)

-- Quick navigation within file
vim.keymap.set('n', '<leader><Up>', '0k', opts)
vim.keymap.set('n', '<leader><Down>', '0j', opts)
vim.keymap.set('v', '<leader><Up>', '0k', opts)
vim.keymap.set('v', '<leader><Down>', '0j', opts)

-- Search and replace
vim.keymap.set('n', '<C-g>', ':s/', opts)
vim.keymap.set('v', '<C-g>', ':s/', opts)
vim.keymap.set('n', '<C-f>', '/', opts)
vim.keymap.set('n', '<C-d>', '#', opts)

-- Clear search highlight
vim.keymap.set('n', '<leader>n', ':nohlsearch<CR>', opts)
vim.keymap.set('n', '<Esc>', ':nohlsearch<CR>', opts)

-- Terminal toggles and movement
vim.keymap.set('n', '<C-Esc>', ':ToggleTerm<CR>', opts)
vim.keymap.set('t', '<C-Esc>', '<Cmd>ToggleTerm<CR>', opts)

-- Terminal window navigation with Command + Arrow keys
vim.keymap.set('t', '<D-Left>', '<Cmd>wincmd h<CR>', opts)
vim.keymap.set('t', '<D-Down>', '<Cmd>wincmd j<CR>', opts)
vim.keymap.set('t', '<D-Up>', '<Cmd>wincmd k<CR>', opts)
vim.keymap.set('t', '<D-Right>', '<Cmd>wincmd l<CR>', opts)

-- Fallback: Ctrl + hjkl for terminal navigation
vim.keymap.set('t', '<C-j>', '<Cmd>wincmd j<CR>', opts)
vim.keymap.set('t', '<C-k>', '<Cmd>wincmd k<CR>', opts)
vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], opts)

-- Buffer navigation (Tab and Shift+Tab are used instead)
-- Use <Tab> and <S-Tab> defined above (lines 23-24)
