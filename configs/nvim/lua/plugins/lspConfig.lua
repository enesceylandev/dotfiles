return {
  {
    'williamboman/mason.nvim',
    config = function()
      require('mason').setup()
    end,
  },
  {
    'williamboman/mason-lspconfig.nvim',
    config = function()
      require('mason-lspconfig').setup {
        ensure_installed = { 'html', 'lua_ls', 'ts_ls', 'eslint', 'harper_ls' },
      }
    end,
  },
  {
    'neovim/nvim-lspconfig',
    config = function()
      local lspconfig = require 'lspconfig'
      lspconfig.html.setup {}
      lspconfig.lua_ls.setup {}
      lspconfig.ts_ls.setup {}
      lspconfig.eslint.setup {}

      -- Keymaps for basic LSP functionality
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { noremap = true, silent = true, desc = '[G]oto [D]efinition' })
      vim.keymap.set('n', 'gr', ':Telescope lsp_references<CR>',
        { noremap = true, silent = true, desc = '[G]oto [R]eferences' })
      vim.keymap.set('n', '<leader>h', vim.lsp.buf.hover, { noremap = true, silent = true, desc = '[H]over' })
      vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action,
        { noremap = true, silent = true, desc = '[C]ode [A]ctions' })
      vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename, { noremap = true, silent = true, desc = '[R]ename' })

      vim.keymap.set('n', '<leader>ci', ':lua vim.lsp.buf.code_action({ context = { only = { "source.removeUnused" } } })<CR>',
        { noremap = true, silent = true, desc = 'Remove [C]ode [I]mports' })
    end,
  },
}
