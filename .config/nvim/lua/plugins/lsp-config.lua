return {
	{
		"williamboman/mason.nvim",
		config = function()
			-- setup mason with default properties
			require("mason").setup()
		end,
	},
	-- mason lsp config utilizes mason to automatically ensure lsp servers you want installed are installed
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			-- ensure that we have lua language server, typescript launguage server
			require("mason-lspconfig").setup({
				ensure_installed = { "eslint", "ts_ls", "lua_ls" },
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
		},
		config = function()
			-- get access to the lspconfig plugins functions
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Dart LSP
			-- vim.lsp.config["dartls"] = {
			-- 	cmd = { "dart", "language-server", "--protocol=lsp" },
			-- 	filetypes = { "dart" },
			-- 	capabilities = capabilities,
			-- 	init_options = {
			-- 		closingLabels = true,
			-- 		flutterOutline = true,
			-- 		onlyAnalyzeProjectsWithOpenFiles = true,
			-- 		outline = true,
			-- 		suggestFromUnimportedLibraries = true,
			-- 	},
			-- 	settings = {
			-- 		dart = {
			-- 			completeFunctionCalls = true,
			-- 			showTodos = true,
			-- 		},
			-- 	},
			-- }
			-- vim.lsp.start(vim.lsp.config["dartls"])

			-- Lua LSP
			vim.lsp.config["lua_ls"] = {
				capabilities = capabilities,
			}
			vim.lsp.start(vim.lsp.config["lua_ls"])

			-- TypeScript/JavaScript LSP
			vim.lsp.config["ts_ls"] = {
				capabilities = capabilities,
				on_attach = function(client, bufnr)
					client.server_capabilities.documentFormattingProvider = false
				end,
				init_options = {
					preferences = {
						disableSuggestions = false,
					},
				},
			}
			vim.lsp.start(vim.lsp.config["ts_ls"])

			-- Key mappings
			local opts = { noremap = true, silent = true, desc = "[C]ode" }

			vim.keymap.set("n", "<leader>ch", vim.lsp.buf.hover, { desc = "[C]ode [H]over Documentation" })
			vim.keymap.set("n", "<leader>cd", vim.lsp.buf.definition, { desc = "[C]ode Goto [D]efinition" })
			vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "[C]ode [A]ctions" })
			vim.keymap.set(
				"n",
				"<leader>cr",
				require("telescope.builtin").lsp_references,
				{ desc = "[C]ode Goto [R]eferences" }
			)
			vim.keymap.set(
				"n",
				"<leader>ci",
				require("telescope.builtin").lsp_implementations,
				{ desc = "[C]ode Goto [I]mplementations" }
			)
			vim.keymap.set("n", "<leader>cR", vim.lsp.buf.rename, { desc = "[C]ode [R]ename" })
			vim.keymap.set("n", "<leader>cD", vim.lsp.buf.declaration, { desc = "[C]ode Goto [D]eclaration" })
		end,
	},
}
