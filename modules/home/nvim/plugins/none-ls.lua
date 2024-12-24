-- return {}
-- Format on save and linters
return {
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
        'shfmt',
      },
      -- auto-install configured formatters & linters (with null-ls)
      automatic_installation = true,
    }

    local sources = {
      diagnostics.checkmake,
      formatting.prettier,
      formatting.stylua,
      formatting.shfmt.with { args = { '-i', '2' } },
    }

    local augroup = vim.api.nvim_create_augroup('LspFormatting', {})
    null_ls.setup {
      -- debug = true, -- Enable debug mode. Inspect logs with :NullLsLog.
      sources = sources,
      -- you can reuse a shared lspconfig on_attach callback here
      on_attach = function(client, bufnr)
        if client.supports_method 'textDocument/formatting' then
          vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
          vim.api.nvim_create_autocmd('BufWritePre', {
            group = augroup,
            buffer = bufnr,
            callback = function()
              -- Asynchronous formatting
              vim.lsp.buf.format { async = true }
            end,
          })
        end
      end,
    }
  end,
} -- Format on save and linters
