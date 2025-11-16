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
        ensure_installed = { 'html', 'lua_ls', 'eslint', 'harper_ls' },
      }
    end,
  },
  {
    'neovim/nvim-lspconfig',
    config = function()
      -- Common on_attach function for all servers
      local on_attach = function(client, bufnr)
        -- Keymaps for basic LSP functionality
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr, noremap = true, silent = true, desc = '[G]oto [D]efinition' })
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = bufnr, noremap = true, silent = true, desc = '[G]oto [R]eferences' })
        vim.keymap.set('n', '<leader>h', vim.lsp.buf.hover, { buffer = bufnr, noremap = true, silent = true, desc = '[H]over' })
        vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, { buffer = bufnr, noremap = true, silent = true, desc = '[C]ode [A]ctions' })
        vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename, { buffer = bufnr, noremap = true, silent = true, desc = '[R]ename' })
        vim.keymap.set('n', '<leader>ci', ':lua vim.lsp.buf.code_action({ context = { only = { "source.removeUnused" } } })<CR>', { buffer = bufnr, noremap = true, silent = true, desc = 'Remove [C]ode [I]mports' })
      end

      -- ts_ls disabled due to root_dir bug in nvim-lspconfig
      -- Using eslint and other servers for now
      -- TODO: Re-enable when lspconfig fixes the root_dir issue

      local servers = { 'html', 'lua_ls', 'eslint' }

      for _, server in ipairs(servers) do
        vim.lsp.config(server, {
          on_attach = on_attach,
        })
        vim.lsp.enable(server)
      end
    end,
  },
}
