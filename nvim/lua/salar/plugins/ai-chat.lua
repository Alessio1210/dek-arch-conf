return {
	{
		"olimorris/codecompanion.nvim",
		event = "VeryLazy",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"hrsh7th/nvim-cmp",
			"nvim-mini/mini.pick",
			"ibhagwan/fzf-lua",
			"stevearc/dressing.nvim",
			"folke/snacks.nvim",
			"nvim-tree/nvim-web-devicons",
			"zbirenbaum/copilot.lua",
		},
		keys = {
			{
				"<leader>aa",
				"<cmd>CodeCompanionChat Toggle<CR>",
				mode = { "n", "v" },
				desc = "AI chat toggle",
			},
			{
				"<leader>an",
				"<cmd>CodeCompanionChat<CR>",
				mode = { "n", "v" },
				desc = "AI chat new",
			},
			{
				"<leader>ae",
				"<cmd>CodeCompanion<CR>",
				mode = { "n", "v" },
				desc = "AI inline edit",
			},
			{
				"<leader>af",
				"<cmd>CodeCompanionActions<CR>",
				mode = { "n", "v" },
				desc = "AI actions",
			},
			{
				"<leader>ar",
				"<cmd>CodeCompanionChat RefreshCache<CR>",
				mode = { "n", "v" },
				desc = "AI refresh chat cache",
			},
			{
				"<leader>az",
				"<cmd>CodeCompanionCLI agent=codex<CR>",
				mode = { "n", "v" },
				desc = "AI Codex CLI",
			},
			{
				"<leader>aA",
				"<cmd>CodeCompanionChat Add<CR>",
				mode = "v",
				desc = "AI add selection to chat",
			},
		},
		opts = {
			display = {
				action_palette = {
					provider = "snacks",
				},
				chat = {
					auto_scroll = true,
					show_header_separator = false,
					show_settings = false,
					start_in_insert_mode = true,
					window = {
						layout = "vertical",
						position = "right",
						width = 0.42,
						full_height = true,
						sticky = false,
						opts = {
							breakindent = true,
							linebreak = true,
							wrap = true,
						},
					},
				},
				diff = {
					enabled = true,
				},
			},
			extensions = {},
			interactions = {
				chat = {
					adapter = {
						name = "chatgpt",
					},
					keymaps = {
						change_adapter = {
							modes = { n = "<leader>cm" },
						},
					},
					opts = {
						completion_provider = "cmp",
						context_management = {
							enabled = false,
						},
					},
					tools = {
						opts = {
							-- Give HTTP chat adapters (including local Ollama) the
							-- approval-gated file, edit, search, and command tools.
							default_tools = { "agent" },
							auto_submit_errors = true,
							auto_submit_success = true,
						},
					},
				},
				inline = {
					adapter = "copilot",
				},
				cli = {
					agent = "codex",
					agents = {
						codex = {
							cmd = "codex",
							args = {},
							description = "Codex CLI",
							provider = "terminal",
						},
					},
				},
			},
			adapters = {
				acp = {
					opts = {
						-- Only show the adapters configured below in the chat picker.
						show_presets = false,
					},
					chatgpt = function()
						-- Use the ACP loader directly: with presets hidden, the generic
						-- adapter helper cannot infer that `codex` is an ACP adapter.
						return require("codecompanion.adapters.acp").extend("codex", {
							name = "chatgpt",
							formatted_name = "ChatGPT",
							commands = {
								default = {
									"npx",
									"-y",
									"@agentclientprotocol/codex-acp",
								},
							},
							env = {
								OPENAI_API_KEY = function()
									return nil
								end,
								CODEX_API_KEY = function()
									return nil
								end,
							},
							defaults = {
								auth_method = "chat-gpt",
								session_config_options = {
									model = "gpt-5.4",
								},
							},
						})
					end,
				},
				http = {
					opts = {
						-- Keep the adapter chooser focused on Ollama.
						show_presets = false,
						show_model_choices = true,
					},
					ollama = function()
						-- Always use the local Ollama server. Its built-in model picker
						-- queries /api/tags and shows the models you have installed.
						return require("codecompanion.adapters").extend("ollama", {
							env = {
								url = "http://127.0.0.1:11434",
							},
						})
					end,
				},
			},
			opts = {
				log_level = "ERROR",
			},
		},
	},
}
