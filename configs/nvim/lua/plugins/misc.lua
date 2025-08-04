return {
  {
    'folke/which-key.nvim',
  },
  {
    'tpope/vim-sleuth',
  },
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = true,
    opts = {},
  },
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
  {
    'norcalli/nvim-colorizer.lua',
    config = function()
      require('colorizer').setup()
    end,
  },
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end,       desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    },
  },
  {
    'numToStr/Comment.nvim',
    event = "VeryLazy",
    dependencies = {
      'JoosepAlviste/nvim-ts-context-commentstring',
    },
    config = function()
      require('ts_context_commentstring').setup({
        -- opsiyonel config, çoğu durumda default yeterli
        enable_autocmd = false,
      })

      require('Comment').setup({
        pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
      })
    end,
  },
  {
      'lukas-reineke/indent-blankline.nvim',
      main = 'ibl',
      opts = {
          indent = {
              char = '▏',
          },
          scope = {
              show_start = false,
              show_end = false,
              show_exact_scope = false,
          },
          exclude = {
              filetypes = {
                  'help',
                  'startify',
                  'dashboard',
                  'packer',
                  'neogitstatus',
                  'NvimTree',
                  'Trouble',
              },
          },
      },
  },
  { 'rafamadriz/friendly-snippets' },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' },
    opts = {},
  },
}

