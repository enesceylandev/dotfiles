return {
  'supermaven-inc/supermaven-nvim',
  config = function()
    require('supermaven-nvim').setup {
      keymaps = {
        accept_suggestion = '<Tab>',
        clear_suggestion = '<C-]>',
        accept_word = '<C-j>',
      },
      ignore_filetypes = { c = true, markdown = true },
      color = {
        suggestion_color = '#454c75',
        cterm = 244,
      },
    }
  end,
}
