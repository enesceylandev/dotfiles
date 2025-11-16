return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    require('toggleterm').setup {
      open_mapping = '<C-">', -- Control + " tuşu ile aç
      direction = 'horizontal', -- Alt kısımda açılsın
      size = 15, -- Terminal yüksekliği
    }
  end,
}
