local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local output = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })

  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "lazy.nvim konnte nicht installiert werden:\n", "ErrorMsg" },
      { output, "WarningMsg" },
    }, true, {})
    return
  end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- Muss vor den LazyVim-Erweiterungen verfügbar sein, die Alpha-Buttons
    -- ergänzen können. Das angezeigte Layout wird in plugins/alpha.lua gesetzt.
    {
      "goolord/alpha-nvim",
      opts = function()
        return require("alpha.themes.dashboard")
      end,
    },

    -- LazyVim-Grundkonfiguration
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- Lädt automatisch jede Datei aus lua/plugins/
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = {
    colorscheme = { "tokyonight", "habamax" },
  },
  checker = {
    enabled = true,
    notify = false,
  },
})
