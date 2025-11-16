return {
  'pmizio/typescript-tools.nvim',
  dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
  config = function()
    require('typescript-tools').setup {
      on_attach = function(client, bufnr)
        -- Keymaps for basic LSP functionality
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr, noremap = true, silent = true, desc = '[G]oto [D]efinition' })
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = bufnr, noremap = true, silent = true, desc = '[G]oto [R]eferences' })
        vim.keymap.set('n', '<leader>h', vim.lsp.buf.hover, { buffer = bufnr, noremap = true, silent = true, desc = '[H]over' })
        vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, { buffer = bufnr, noremap = true, silent = true, desc = '[C]ode [A]ctions' })
        vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename, { buffer = bufnr, noremap = true, silent = true, desc = '[R]ename' })
      end,
    }
  end,
}
