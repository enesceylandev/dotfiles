return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },

  config = function()
    local harpoon = require("harpoon")
    harpoon:setup()
  end,

  keys = {
    { "<leader>A", function() require("harpoon").get_mark_config():add() end, desc = "harpoon file" },
    { "<leader>a", function() require("harpoon").ui:toggle_quick_menu() end, desc = "harpoon quick menu" },
    { "<leader>1", function() require("harpoon").get_mark_config():select(1) end, desc = "harpoon to file 1" },
    { "<leader>2", function() require("harpoon").get_mark_config():select(2) end, desc = "harpoon to file 2" },
    { "<leader>3", function() require("harpoon").get_mark_config():select(3) end, desc = "harpoon to file 3" },
    { "<leader>4", function() require("harpoon").get_mark_config():select(4) end, desc = "harpoon to file 4" },
    { "<leader>5", function() require("harpoon").get_mark_config():select(5) end, desc = "harpoon to file 5" },
  }
}

