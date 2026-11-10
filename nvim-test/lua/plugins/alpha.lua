return {
  -- LazyVims Standard-Dashboard deaktivieren, damit Alpha die Startseite übernimmt.
  { "folke/snacks.nvim", opts = { dashboard = { enabled = false } } },

  {
    "goolord/alpha-nvim",
    lazy = false,
    priority = 1001,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local startify = require("alpha.themes.startify")
      startify.file_icons.provider = "devicons"
      require("alpha").setup(startify.config)
    end,
  },
}
