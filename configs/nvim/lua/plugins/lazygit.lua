return {
  'kdheepak/lazygit.nvim',
  cmd = {
    'LazyGit',
    'LazyGitConfig',
    'LazyGitCurrentFile',
    'LazyGitFilter',
    'LazyGitFilterCurrentFile',
  },
  keys = {
    { '<leader>lg', '<cmd>LazyGit<cr>', desc = 'LazyGit' },
    { '<leader>lf', '<cmd>LazyGitFilterCurrentFile<cr>', desc = 'LazyGit Current File Commits' },
  },
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  config = function()
    vim.api.nvim_create_autocmd('TermOpen', {
      pattern = 'term://*lazygit*',
      callback = function(args)
        vim.keymap.set('t', '<Esc>', '<Esc>', { buffer = args.buf })
      end,
    })
  end,
}
