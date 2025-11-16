return {
  'akinsho/bufferline.nvim',
  dependencies = {
    'moll/vim-bbye',
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    -- vim.opt.linespace = 8

    require('bufferline').setup {
      options = {
        mode = 'buffers',                    -- set to "tabs" to only show tabpages instead
        themable = true,                     -- allows highlight groups to be overriden i.e. sets highlights as default
        numbers = 'none',                    -- | "ordinal" | "buffer_id" | "both" | function({ ordinal, id, lower, raise }): string,
        close_command = 'Bdelete! %d',       -- can be a string | function, see "Mouse actions"
        right_mouse_command = 'Bdelete! %d', -- can be a string | function, see "Mouse actions"
        left_mouse_command = 'buffer %d',    -- can be a string | function, see "Mouse actions"
        middle_mouse_command = nil,          -- can be a string | function, see "Mouse actions"
        -- buffer_close_icon = '󰅖',
        buffer_close_icon = '✗',
        -- buffer_close_icon = '✕',
        close_icon = '',
        path_components = 1, -- Show only the file name without the directory
        modified_icon = '●',
        left_trunc_marker = '',
        right_trunc_marker = '',
        max_name_length = 30,
        max_prefix_length = 30, -- prefix used when a buffer is de-duplicated
        tab_size = 21,
        diagnostics = false,
        diagnostics_update_in_insert = false,
        color_icons = true,
        show_buffer_icons = true,
        show_buffer_close_icons = true,
        show_close_icon = true,
        persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
        separator_style = { '│', '│' }, -- | "thick" | "thin" | { 'any', 'any' },
        enforce_regular_tabs = true,
        always_show_bufferline = true,
        show_tab_indicators = false,
        indicator = {
          -- icon = '▎', -- this should be omitted if indicator style is not 'icon'
          style = 'none', -- Options: 'icon', 'underline', 'none'
        },
        icon_pinned = '󰐃',
        minimum_padding = 1,
        maximum_padding = 5,
        maximum_length = 15,
        sort_by = 'insert_at_end',
      },
      highlights = {
        separator = {
          fg = '#434C5E',
        },
        buffer_selected = {
          bold = true,
          italic = false,
        },
        -- separator_selected = {},
        -- tab_selected = {},
        -- background = {},
        -- indicator_selected = {},
        -- fill = {},
      },
    }

    -- Keymaps
    local opts = { noremap = true, silent = true, desc = 'Go to Buffer' }
    vim.keymap.set('n', '<Tab>', '<Cmd>BufferLineCycleNext<CR>', {})
    vim.keymap.set('n', '<S-Tab>', '<Cmd>BufferLineCyclePrev<CR>', {})

    -- Command + 1-9 to switch between buffers
    vim.keymap.set('n', '<D-1>', "<cmd>lua require('bufferline').go_to_buffer(1, true)<CR>", opts)
    vim.keymap.set('n', '<D-2>', "<cmd>lua require('bufferline').go_to_buffer(2, true)<CR>", opts)
    vim.keymap.set('n', '<D-3>', "<cmd>lua require('bufferline').go_to_buffer(3, true)<CR>", opts)
    vim.keymap.set('n', '<D-4>', "<cmd>lua require('bufferline').go_to_buffer(4, true)<CR>", opts)
    vim.keymap.set('n', '<D-5>', "<cmd>lua require('bufferline').go_to_buffer(5, true)<CR>", opts)
    vim.keymap.set('n', '<D-6>', "<cmd>lua require('bufferline').go_to_buffer(6, true)<CR>", opts)
    vim.keymap.set('n', '<D-7>', "<cmd>lua require('bufferline').go_to_buffer(7, true)<CR>", opts)
    vim.keymap.set('n', '<D-8>', "<cmd>lua require('bufferline').go_to_buffer(8, true)<CR>", opts)
    vim.keymap.set('n', '<D-9>', "<cmd>lua require('bufferline').go_to_buffer(9, true)<CR>", opts)

    -- Close buffers to the right
    vim.keymap.set('n', '<leader>bl', function()
      local current_buf = vim.fn.bufnr('%')
      local bufs = vim.fn.getbufinfo({ buflisted = 1 })

      for _, buf in ipairs(bufs) do
        if buf.bufnr > current_buf then
          vim.cmd('bdelete! ' .. buf.bufnr)
        end
      end
    end, { noremap = true, silent = true, desc = 'Close buffers to the right' })

    -- Close buffers to the left
    vim.keymap.set('n', '<leader>br', function()
      local current_buf = vim.fn.bufnr('%')
      local bufs = vim.fn.getbufinfo({ buflisted = 1 })

      for _, buf in ipairs(bufs) do
        if buf.bufnr < current_buf then
          vim.cmd('bdelete! ' .. buf.bufnr)
        end
      end
    end, { noremap = true, silent = true, desc = 'Close buffers to the left' })
  end,
}
