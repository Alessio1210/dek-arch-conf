return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		local rndr = require("rndr")

		telescope.setup({
			defaults = {
				buffer_previewer_maker = rndr.telescope_buffer_previewer_maker,
				file_ignore_patterns = {
					"node_modules",
					"vendor",
					"build",
					"%.git",
					"%.next",
					".settings/",
					".class$",
					"dist/",
					".png",
					"jpg",
					"package-lock.json",
					"%.zed",
					"node_modules",
					"%.cache",
					"%.pkl",
					"%.parquet",
					"%.log",
					"%.pyc",
					".idea/",
					".vscode/",
					"%.xml",
					".xlsx",
					"%.toml",
					"%.iml",
					"%.cfg",
					"%.pyd",
					"%.exe",
					"%.dll",
					"%.pyx",
					"%.map",
					".%pdf",
					".idea/%",

				path_display = { "smart" },
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous,
						["<C-j>"] = actions.move_selection_next,
						["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
						["<C-t>"] = require("trouble.sources.telescope").open,
					},
				},
			},
		}})

		pcall(telescope.load_extension, "fzf")

		local keymap = vim.keymap
		keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find recent files" })
		keymap.set("n", "<leader>fw", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
		keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", {
			desc = "Find string under cursor in cwd",
		})

		local function current_buffer_fuzzy_find_safe()
			local builtin = require("telescope.builtin")
			local themes = require("telescope.themes")
			local treesitter_query = vim.treesitter.query
			local original_get_query = treesitter_query and treesitter_query.get or vim.treesitter.get_query

			local function empty_query()
				return {
					captures = {},
					iter_captures = function()
						return function()
							return nil
						end
					end,
				}
			end

			local function wrapped_get_query(...)
				local query = original_get_query(...)
				if query == nil then
					return empty_query()
				end
				return query
			end

			if treesitter_query and treesitter_query.get then
				treesitter_query.get = wrapped_get_query
			elseif vim.treesitter.get_query then
				vim.treesitter.get_query = wrapped_get_query
			end

			local function restore_query_getter()
				if treesitter_query and treesitter_query.get then
					treesitter_query.get = original_get_query
				elseif vim.treesitter.get_query then
					vim.treesitter.get_query = original_get_query
				end
			end

			local function invoke()
				builtin.current_buffer_fuzzy_find(themes.get_dropdown({
					winblend = 10,
					previewer = false,
					layout_strategy = "vertical",
					layout_config = {
						prompt_position = "top",
						width = 0.4,
						height = 0.3,
						anchor = "NE",
					},
				}))
			end

			local ok, err = xpcall(invoke, debug.traceback)
			restore_query_getter()

			if not ok then
				error(err)
			end
		end

		vim.keymap.set("n", "<leader>/", current_buffer_fuzzy_find_safe, { desc = "[/] Fuzzily search in current buffer" })
	end,
}
