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
        ensure_installed = { 'html', 'lua_ls', 'eslint' },
      }
    end,
  },
  {
    'neovim/nvim-lspconfig',
    config = function()
      local on_attach = function(client, bufnr)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr, noremap = true, silent = true, desc = '[G]oto [D]efinition' })
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = bufnr, noremap = true, silent = true, desc = '[G]oto [R]eferences' })
        vim.keymap.set('n', '<leader>h', vim.lsp.buf.hover, { buffer = bufnr, noremap = true, silent = true, desc = '[H]over' })
        vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, { buffer = bufnr, noremap = true, silent = true, desc = '[C]ode [A]ctions' })
        vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename, { buffer = bufnr, noremap = true, silent = true, desc = '[R]ename' })
        vim.keymap.set(
          'n',
          '<leader>ci',
          ':lua vim.lsp.buf.code_action({ context = { only = { "source.removeUnused" } } })<CR>',
          { buffer = bufnr, noremap = true, silent = true, desc = 'Remove [C]ode [I]mports' }
        )
      end

      -- ts_ls disabled due to root_dir bug in nvim-lspconfig
      -- typescript-tools.nvim is used instead for TypeScript/JavaScript
      for _, server in ipairs({ 'html', 'lua_ls', 'eslint' }) do
        vim.lsp.config(server, { on_attach = on_attach })
        vim.lsp.enable(server)
      end

      _G.lsp_on_attach = on_attach
    end,
  },
  {
    'pmizio/typescript-tools.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
    config = function()
      require('typescript-tools').setup {
        on_attach = _G.lsp_on_attach,
      }
    end,
  },
  {
    'nvimtools/none-ls.nvim',
    dependencies = {
      'nvimtools/none-ls-extras.nvim',
      'jayp0521/mason-null-ls.nvim', -- ensure dependencies are installed
    },
    config = function()
      local null_ls = require 'null-ls'
      local formatting = null_ls.builtins.formatting   -- to setup formatters
      local diagnostics = null_ls.builtins.diagnostics -- to setup linters

      -- list of formatters & linters for mason to install
      require('mason-null-ls').setup {
        ensure_installed = {
          'checkmake',
          'prettier', -- ts/js formatter
          'stylua',   -- lua formatter
          'eslint_d', -- ts/js linter
          -- 'shfmt',
        },
        -- auto-install configured formatters & linters (with null-ls)
        automatic_installation = true,
      }

      local sources = {
        diagnostics.checkmake,
        formatting.prettier,
        formatting.stylua,
      }

      local augroup = vim.api.nvim_create_augroup('LspFormatting', {})
      null_ls.setup {
        -- debug = true, -- Enable debug mode. Inspect logs with :NullLsLog.
        sources = sources,
        -- you can reuse a shared lspconfig on_attach callback here
        on_attach = function(client, bufnr)
          -- Yalnızca null-ls formatlama yapabilsin
          if client.name == "tsserver" or client.name == "eslint" then
            client.server_capabilities.documentFormattingProvider = false
          end

          if client:supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = augroup,
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format {
                  async = true,
                  filter = function(format_client)
                    -- SADECE null-ls formatlama yapsın
                    return format_client.name == "null-ls"
                  end,
                }
              end,
            })
          end
        end
      }
    end,
  },
}
