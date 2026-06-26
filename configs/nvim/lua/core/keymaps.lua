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

-- Window navigation (Command + hjkl for Kitty terminal)
vim.keymap.set('n', '<D-h>', '<C-w>h', opts)
vim.keymap.set('n', '<D-j>', '<C-w>j', opts)
vim.keymap.set('n', '<D-k>', '<C-w>k', opts)
vim.keymap.set('n', '<D-l>', '<C-w>l', opts)

-- Also keep Space + hjkl as fallback
vim.keymap.set('n', '<leader>h', '<C-w>h', opts)
vim.keymap.set('n', '<leader>j', '<C-w>j', opts)
vim.keymap.set('n', '<leader>k', '<C-w>k', opts)
vim.keymap.set('n', '<leader>l', '<C-w>l', opts)

-- Window resizing (Shift + Command + hjkl)
vim.keymap.set('n', '<D-S-h>', ':vertical resize -5<CR>', opts)
vim.keymap.set('n', '<D-S-l>', ':vertical resize +5<CR>', opts)
vim.keymap.set('n', '<D-S-k>', ':resize -5<CR>', opts)
vim.keymap.set('n', '<D-S-j>', ':resize +5<CR>', opts)

-- Terminal window resizing
vim.keymap.set('t', '<D-S-h>', '<Cmd>vertical resize -5<CR>', opts)
vim.keymap.set('t', '<D-S-l>', '<Cmd>vertical resize +5<CR>', opts)
vim.keymap.set('t', '<D-S-k>', '<Cmd>resize -5<CR>', opts)
vim.keymap.set('t', '<D-S-j>', '<Cmd>resize +5<CR>', opts)

-- Fallback: Space + M-hjkl for resizing
vim.keymap.set('n', '<leader><M-h>', ':vertical resize -5<CR>', opts)
vim.keymap.set('n', '<leader><M-l>', ':vertical resize +5<CR>', opts)
vim.keymap.set('n', '<leader><M-k>', ':resize -5<CR>', opts)
vim.keymap.set('n', '<leader><M-j>', ':resize +5<CR>', opts)

-- Move lines (Shift + Option + j/k)
vim.keymap.set('n', '<M-S-k>', ':m .-2<CR>==', opts)
vim.keymap.set('n', '<M-S-j>', ':m .+1<CR>==', opts)
vim.keymap.set('v', '<M-S-k>', ":m '<-2<CR>gv=gv", opts)
vim.keymap.set('v', '<M-S-j>', ":m '>+1<CR>gv=gv", opts)

-- Jump to blocks with Shift + j/k
vim.keymap.set('n', '<S-k>', '{', opts) -- Jump to opening brace
vim.keymap.set('n', '<S-j>', '}', opts) -- Jump to closing brace
vim.keymap.set('v', '<S-k>', '{', opts) -- Jump to opening brace (visual mode)
vim.keymap.set('v', '<S-j>', '}', opts) -- Jump to closing brace (visual mode)

-- Search and replace
vim.keymap.set('n', '<C-g>', ':wq!<CR>', opts)
vim.keymap.set('t', '<C-g>', '<Cmd>wq!<CR>', opts)
vim.keymap.set('v', '<C-g>', ':s/', opts)
vim.keymap.set('n', '<C-d>', '#', opts)

-- Clear search highlight
vim.keymap.set('n', '<leader>n', ':nohlsearch<CR>', opts)
vim.keymap.set('n', '<Esc>', ':nohlsearch<CR>', opts)

-- Window zoom (fullscreen current split) toggle with Command+F
-- Kitty sends \x06 (C-f), tmux passes it to nvim when vim is focused
local _zoom_state = false
vim.keymap.set('n', '<C-f>', function()
  if _zoom_state then
    vim.cmd 'wincmd ='
    _zoom_state = false
  else
    vim.cmd 'wincmd _'
    vim.cmd 'wincmd |'
    _zoom_state = true
  end
end, opts)

-- Terminal toggles and movement
vim.keymap.set('n', '<C-Esc>', ':ToggleTerm<CR>', opts)
vim.keymap.set('t', '<C-Esc>', '<Cmd>ToggleTerm<CR>', opts)

-- Terminal window navigation with Command + hjkl
vim.keymap.set('t', '<D-h>', '<Cmd>wincmd h<CR>', opts)
vim.keymap.set('t', '<D-j>', '<Cmd>wincmd j<CR>', opts)
vim.keymap.set('t', '<D-k>', '<Cmd>wincmd k<CR>', opts)
vim.keymap.set('t', '<D-l>', '<Cmd>wincmd l<CR>', opts)

-- Fallback: Ctrl + hjkl for terminal navigation
vim.keymap.set('t', '<C-j>', '<Cmd>wincmd j<CR>', opts)
vim.keymap.set('t', '<C-k>', '<Cmd>wincmd k<CR>', opts)
vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], opts)

-- Tmux navigator (Ctrl + hjkl)
vim.keymap.set('n', '<C-h>', '<cmd>TmuxNavigateLeft<CR>', opts)
vim.keymap.set('n', '<C-j>', '<cmd>TmuxNavigateDown<CR>', opts)
vim.keymap.set('n', '<C-k>', '<cmd>TmuxNavigateUp<CR>', opts)
vim.keymap.set('n', '<C-l>', '<cmd>TmuxNavigateRight<CR>', opts)

-- Quickfix list management
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  callback = function()
    -- @ ile makro çalıştır (tek dosyada birden fazla satır varsa cdo, yoksa cfdo)
    vim.keymap.set('n', '@', function()
      local reg = vim.fn.nr2char(vim.fn.getchar())
      local qflist = vim.fn.getqflist()
      local files = {}
      for _, item in ipairs(qflist) do
        files[item.bufnr] = (files[item.bufnr] or 0) + 1
      end
      local has_multi = false
      for _, count in pairs(files) do
        if count > 1 then
          has_multi = true
          break
        end
      end
      local cmd = has_multi and 'cdo' or 'cfdo'
      vim.cmd(cmd .. ' normal @' .. reg)
    end, { buffer = true, desc = 'Run macro on quickfix list' })

    -- Enter ile seçim yap ve quickfix'i kapat
    vim.keymap.set('n', '<CR>', function()
      local line = vim.fn.line '.'
      vim.cmd 'cclose'
      vim.cmd(line .. 'cc')
    end, { buffer = true, desc = 'Select and close quickfix' })

    -- dd ile mevcut satırı quickfix'ten sil
    vim.keymap.set('n', 'dd', function()
      local qflist = vim.fn.getqflist()
      local line = vim.fn.line '.'
      table.remove(qflist, line)
      vim.fn.setqflist(qflist, 'r')
    end, { buffer = true, desc = 'Remove item from quickfix' })

    -- Visual modda seçili satırları sil
    vim.keymap.set('v', 'd', function()
      local qflist = vim.fn.getqflist()
      local start_line = vim.fn.line 'v'
      local end_line = vim.fn.line '.'
      if start_line > end_line then
        start_line, end_line = end_line, start_line
      end
      for i = end_line, start_line, -1 do
        table.remove(qflist, i)
      end
      vim.fn.setqflist(qflist, 'r')
    end, { buffer = true, desc = 'Remove selected items from quickfix' })
  end,
})

-- Quickfix menüsünü aç
vim.keymap.set('n', '<leader>qq', '<cmd>copen<CR>', opts)

-- LSP diagnostics'i quickfix'e gönder
vim.keymap.set('n', '<leader>qf', function()
  vim.diagnostic.setqflist()
end, { desc = 'Diagnostics to quickfix' })

-- Quickfix navigation (wraps around at start/end)
-- Quickfix navigation: Ctrl+Tab ileri, Ctrl+Shift+Tab geri
vim.keymap.set('n', '<F7>', function()
  if #vim.fn.getqflist() == 0 then
    return
  end
  local ok = pcall(vim.cmd, 'cnext')
  if not ok then
    pcall(vim.cmd, 'cfirst')
  end
end, opts)
vim.keymap.set('n', '<F8>', function()
  if #vim.fn.getqflist() == 0 then
    return
  end
  local ok = pcall(vim.cmd, 'cprev')
  if not ok then
    pcall(vim.cmd, 'clast')
  end
end, opts)

-- Quickfix: mevcut item'ı listeden çıkar (herhangi bir pencereden)
vim.keymap.set('n', '<leader>qd', function()
  local qflist = vim.fn.getqflist()
  local idx = vim.fn.getqflist({ idx = 0 }).idx
  table.remove(qflist, idx)
  vim.fn.setqflist(qflist, 'r')
end, { desc = 'Remove current quickfix item' })

-- Tüm quickfix listesini temizle
vim.keymap.set('n', '<leader>qD', function()
  vim.fn.setqflist({}, 'r')
  vim.cmd 'cclose'
  vim.notify('Quickfix list cleared', vim.log.levels.INFO)
end, { desc = 'Clear all quickfix items' })

-- Mevcut satırı quickfix'e ekle
vim.keymap.set('n', '<leader>qa', function()
  local qflist = vim.fn.getqflist()
  table.insert(qflist, {
    filename = vim.fn.expand '%',
    lnum = vim.fn.line '.',
    col = vim.fn.col '.',
    text = vim.fn.getline '.',
  })
  vim.fn.setqflist(qflist, 'r')
  print 'Added to quickfix'
end, { desc = 'Add current line to quickfix' })

-- Marks listesini Telescope ile göster (sadece kullanıcı tanımlı a-z, A-Z)
local open_marks_picker
open_marks_picker = function()
  local marks = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      for _, m in ipairs(vim.fn.getmarklist(bufnr)) do
        table.insert(marks, m)
      end
    end
  end
  vim.list_extend(marks, vim.fn.getmarklist())

  local items = {}
  local mark_map = {}
  for _, m in ipairs(marks) do
    local mark = m.mark:sub(2)
    if mark:match '[a-zA-Z]' and m.pos[1] ~= 0 then
      local fname = vim.api.nvim_buf_get_name(m.pos[1])
      if fname == '' then
        fname = vim.fn.bufname(m.pos[1])
      end
      local short = vim.fn.fnamemodify(fname, ':~:.')
      local label = string.format('%s  %s:%d', mark, short, m.pos[2])
      table.insert(items, label)
      mark_map[label] = { mark = mark, filename = fname, lnum = m.pos[2], col = m.pos[3] }
    end
  end

  if #items == 0 then
    vim.notify('No marks set', vim.log.levels.INFO)
    return
  end

  require('telescope.pickers')
    .new({}, {
      prompt_title = 'Marks',
      initial_mode = 'normal',
      finder = require('telescope.finders').new_table { results = items },
      sorter = require('telescope.config').values.generic_sorter {},
      attach_mappings = function(prompt_bufnr, map)
        local actions = require 'telescope.actions'
        local action_state = require 'telescope.actions.state'

        actions.select_default:replace(function()
          local sel = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if sel then
            local info = mark_map[sel[1]]
            vim.cmd('edit ' .. info.filename)
            vim.api.nvim_win_set_cursor(0, { info.lnum, info.col })
          end
        end)

        map('n', 'dd', function()
          local sel = action_state.get_selected_entry()
          if sel then
            local mark = sel[1]:sub(1, 1)
            actions.close(prompt_bufnr)
            vim.schedule(function()
              vim.cmd('delmarks ' .. mark)
              open_marks_picker()
            end)
          end
        end)

        return true
      end,
    })
    :find()
end
vim.keymap.set('n', '<leader>qm', open_marks_picker, { desc = '[Q]uickfix [M]arks' })
