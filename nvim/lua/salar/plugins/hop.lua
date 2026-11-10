return {
    'smoka7/hop.nvim',
    config = function()
	require('hop').setup()
	vim.api.nvim_set_keymap("n", '<leader><leader>', "<cmd>lua require'hop'.hint_words()<cr>", {silent = true})
    end
}
