return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  dependencies = {
    "windwp/nvim-ts-autotag",
  },
  config = function()
    local ok, treesitter = pcall(require, "nvim-treesitter")
    if not ok then
      vim.notify("nvim-treesitter could not be loaded", vim.log.levels.WARN)
      return
    end

    local disabled_filetypes = {
      lua = true,
      vim = true,
    }

    -- nvim-treesitter ships a Haskell parser, but not separate parsers for
    -- literate Haskell or Cabal files.
    vim.treesitter.language.register("haskell", "lhaskell")
    vim.treesitter.language.register("sql", "plsql")
    vim.treesitter.language.register("bash", "make")

    treesitter.setup({
      install_dir = vim.fn.stdpath("data") .. "/site",
    })

    local group = vim.api.nvim_create_augroup("salar_treesitter", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      callback = function(args)
        local filetype = vim.bo[args.buf].filetype
        if disabled_filetypes[filetype] then
          pcall(vim.treesitter.stop, args.buf)
          if filetype == "lua" then
            vim.bo[args.buf].syntax = "lua"
          end
          return
        end

      end,
    })
  end,
}
