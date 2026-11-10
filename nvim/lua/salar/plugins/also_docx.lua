return{
  "daanh/nvim-docx",
  config = function()
    require("nvim-docx").setup({
      debug = false,
      auto_cleanup = true,
    })
  end,
}
