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
        ensure_installed = { "eslint", "ts_ls", "lua_ls", "tailwindcss" },
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
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Key mappings
      local on_attach = function(client, bufnr)
        client.server_capabilities.documentFormattingProvider = false

        local opts = { noremap = true, silent = true, buffer = bufnr }

        vim.keymap.set("n", "<leader>ch", vim.lsp.buf.hover, vim.tbl_extend("force", opts, {
          desc = "[C]ode [H]over Documentation",
        }))
        vim.keymap.set("n", "<leader>cd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, {
          desc = "[C]ode Goto [D]efinition",
        }))
        vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, {
          desc = "[C]ode [A]ctions",
        }))
        vim.keymap.set("n", "<leader>cr", Snacks.picker.lsp_references, vim.tbl_extend("force", opts, {
          desc = "[C]ode Goto [R]eferences",
        }))
        vim.keymap.set(
          "n",
          "<leader>ci",
          Snacks.picker.lsp_implementations,
          vim.tbl_extend("force", opts, {
            desc = "[C]ode Goto [I]mplementations",
          })
        )
        vim.keymap.set("n", "<leader>cR", vim.lsp.buf.rename, vim.tbl_extend("force", opts, {
          desc = "[C]ode [R]ename",
        }))
        vim.keymap.set("n", "<leader>cD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, {
          desc = "[C]ode Goto [D]eclaration",
        }))
      end

      -- Dart LSP
      vim.lsp.config("dartls", {
        cmd = { "dart", "language-server", "--protocol=lsp" },
        filetypes = { "dart" },
        capabilities = capabilities,
        on_attach = on_attach,
        init_options = {
          closingLabels = true,
          flutterOutline = true,
          onlyAnalyzeProjectsWithOpenFiles = true,
          outline = true,
          suggestFromUnimportedLibraries = true,
        },
        settings = {
          dart = {
            completeFunctionCalls = true,
            showTodos = true,
          },
        },
      })
      vim.lsp.enable("dartls")

      -- Lua LSP
      vim.lsp.config("lua_ls", {
        capabilities = capabilities,
        on_attach = on_attach,
      })
      vim.lsp.enable("lua_ls")

      -- TypeScript/JavaScript LSP
      vim.lsp.config("ts_ls", {
        capabilities = capabilities,
        on_attach = on_attach,
        init_options = {
          preferences = {
            disableSuggestions = false,
          },
        },
      })
      vim.lsp.enable("ts_ls")

      -- Tailwind CSS LSP
      vim.lsp.config("tailwindcss", {
        capabilities = capabilities,
        on_attach = on_attach,
        filetypes = {
          "html",
          "css",
          "scss",
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "tsx",
          "vue",
          "svelte",
          "astro",
        },
        root_markers = {
          {
          "tailwind.config.js",
          "tailwind.config.cjs",
          "tailwind.config.mjs",
          "tailwind.config.ts",
          "postcss.config.js",
          "postcss.config.cjs",
          "package.json",
          },
          { ".git" },
        },
      })
      vim.lsp.enable("tailwindcss")
    end,
  },
}
