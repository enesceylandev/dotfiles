require 'core.options'
require 'core.keymaps'

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup {
  require 'plugins.autocompilation',
  require 'plugins.bufferline',
  require 'plugins.gitblame',
  require 'plugins.gitsigns',
  require 'plugins.lspConfig',
  require 'plugins.typescript',
  require 'plugins.nvim-surround',
  require 'plugins.nvimUfo',
  require 'plugins.none-ls',
  require 'plugins.supermaven',
  require 'plugins.toggleTerm',
  require 'plugins.lazygit',
  require 'plugins.misc',
  -- require 'plugins.yazi',
  -- require 'plugins.harpoon',

  require 'plugins.tsAutotag',
  require 'plugins.treesitter',

  require 'plugins.neotree',
  require 'plugins.telescope',
  require 'plugins.dashboard',

  require 'plugins.colorTheme',

  -- require 'plugins.lualine',
  -- require 'plugins.chatgpt',
  -- require 'plugins.persistence',
}
