return {
    "windwp/nvim-ts-autotag",
    ft = {"html", "javascriptreact", "typescriptreact", "svelt", "vue", "tsx", "jsx", "rescript", "python"},
    config = function()
	require("nvim-ts-autotag").setup()
    end,
}
