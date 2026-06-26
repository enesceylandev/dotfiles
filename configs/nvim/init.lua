vim.deprecate = function() end

-- Suppress "position encoding param is required" warning from Telescope
local orig_notify = vim.notify
vim.notify = function(msg, ...)
  if type(msg) == 'string' and msg:find 'position_encoding param is required' then
    return
  end
  orig_notify(msg, ...)
end

require 'core.options'
require 'core.keymaps'
require 'core.macros'

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
  require 'plugins.nvim-surround',
  require 'plugins.nvimUfo',
  require 'plugins.supermaven',
  require 'plugins.toggleTerm',
  require 'plugins.misc',
  require 'plugins.lazygit',
  require 'plugins.vim-tmux-navigator',
  require 'plugins.tsAutotag',
  require 'plugins.neotree',
  require 'plugins.telescope',
  require 'plugins.dashboard',
  require 'plugins.colorTheme',

  -- Language Servers & Formatters
  require 'plugins.lspConfig',
  require 'plugins.treesitter',
}
