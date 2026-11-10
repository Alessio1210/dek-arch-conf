return {
	{
		"Kurren123/mssql.nvim",
		ft = { "sql" },
		cmd = { "MSSQL" },
		dependencies = {
			"folke/which-key.nvim",
		},
		opts = {
			keymap_prefix = "<leader>m",
			open_results_in = "current_window",
			results_buffer_filetype = "",
			max_rows = 300,
		},
		keys = {
			{
				"<leader>sr",
				function()
					require("mssql").execute_query()
				end,
				mode = { "n", "v" },
				desc = "MSSQL execute query",
			},
			{
				"<leader>st",
				function()
					require("mssql").find_object()
				end,
				desc = "MSSQL find object",
			},
		},
		config = function(_, opts)
			require("mssql").setup(opts)

			vim.api.nvim_create_autocmd("BufWinEnter", {
				group = vim.api.nvim_create_augroup("MssqlResultBuffers", { clear = true }),
				callback = function(args)
					if not vim.b[args.buf].query_result_info then
						return
					end

					vim.bo[args.buf].filetype = ""
					local win = vim.api.nvim_get_current_win()
					vim.wo[win].wrap = false
					vim.wo[win].linebreak = false
					vim.wo[win].breakindent = false
				end,
			})
		end,
	},
}
