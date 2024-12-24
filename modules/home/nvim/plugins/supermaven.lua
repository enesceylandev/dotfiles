return {
  'supermaven-inc/supermaven-nvim',
  config = function()
    require('supermaven-nvim').setup {
      keymaps = {
        accept_suggestion = '<S-CR>',
        clear_suggestion = '<S-BS>',
        accept_word = '<S-W>',
      },
      ignore_filetypes = { c = true, markdown = true },
      color = {
        suggestion_color = '#454c75',
        cterm = 244,
      },
    }
  end,
}
