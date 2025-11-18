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
			-- ensure that we have lua language server, typescript launguage server, java language server, and java test language server are installed
			require("mason-lspconfig").setup({
				ensure_installed = { "eslint", "ts_ls", "lua_ls", "jdtls", "phpactor" },
			})
		end,
	},
	-- mason nvim dap utilizes mason to automatically ensure debug adapters you want installed are installed, mason-lspconfig will not automatically install debug adapters for us
	{
		"jay-babu/mason-nvim-dap.nvim",
		config = function()
			-- ensure the java debug adapter is installed
			require("mason-nvim-dap").setup({
				ensure_installed = { "java-debug-adapter", "java-test" },
			})
		end,
	},
	-- utility plugin for configuring the java language server for us
	{
		"mfussenegger/nvim-jdtls",
		dependencies = {
			"mfussenegger/nvim-dap",
		},
	},

	-- {'nvim-java/nvim-java'},

	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
		},
		config = function()
			-- get access to the lspconfig plugins functions
			local lspconfig = require("lspconfig")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			require("lspconfig").prismals.setup({})

			lspconfig.dartls.setup({
				cmd = { "dart", "language-server", "--protocol=lsp" },
				filetypes = { "dart" },
				init_options = {
					closingLabels = true,
					flutterOutline = true,
					onlyAnalyzeProjectsWithOpenFiles = true,
					outline = true,
					suggestFromUnimportedLibraries = true,
				},
				-- root_dir = root_pattern("pubspec.yaml"),
				settings = {
					dart = {
						completeFunctionCalls = true,
						showTodos = true,
					},
				},
			})

			-- setup the lua language server
			lspconfig.lua_ls.setup({
				capabilities = capabilities,
			})

			-- setup the TypeScript/JavaScript server
			lspconfig.ts_ls.setup({
				on_attach = function(client, bufnr)
					-- Update the new field for disabling formatting
					client.server_capabilities.documentFormattingProvider = false
				end,
				capabilities = capabilities,
				init_options = {
					preferences = {
						disableSuggestions = true,
					},
				},
			})

			-- setup Java LSP (jdtls)
			lspconfig.jdtls.setup({
				capabilities = capabilities,
				cmd = { "jdtls" }, -- Ensure jdtls is installed
				root_dir = lspconfig.util.root_pattern("pom.xml", "gradle.build", ".git"),
				settings = {
					java = {
						signatureHelp = { enabled = true },
						contentProvider = { preferred = "fernflower" },
					},
				},
			})

			-- Automatically start jdtls in Java files
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "java",
				callback = function()
					vim.cmd("LspStart jdtls")
				end,
			})

			-- setup PHP LSP (phpactor)
			lspconfig.phpactor.setup({
				capabilities = capabilities,
				cmd = { "phpactor", "language-server" },
				filetypes = { "php" },
				root_dir = lspconfig.util.root_pattern("composer.json", ".git", ".phpactor.json", ".phpactor.yml"),
			})

			-- Auto start PHP LSP when opening php files
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "php",
				callback = function()
					vim.cmd("LspStart phpactor")
				end,
			})

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
