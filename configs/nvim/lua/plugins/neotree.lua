return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
    },
    config = function()
      vim.keymap.set('n', '<leader>e', '<cmd>Neotree toggle position=right<CR>', { noremap = true, silent = true })

      require('neo-tree').setup {
        event_handlers = {
          {
            event = 'file_opened',
            handler = function(file_path)
              if file_path:match '%.png$' or file_path:match '%.jpg$' or file_path:match '%.jpeg$' then
                vim.cmd('silent !xdg-open ' .. file_path .. ' &')
                vim.cmd 'bdelete!'
              end
            end,
          },
        },
      }
    end,
  },
}
