return {
  'stevearc/conform.nvim',
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    formatters_by_ft = {
      ["javascript"] = { "prettierd", "prettier" },
      ["javascriptreact"] = { "prettierd", "prettier" },
      ["typescript"] = { "prettierd", "prettier" },
      ["typescriptreact"] = { "prettierd", "prettier" },
      ["json"] = { "prettierd", "prettier" },
      ["lua"] = { "stylua" },
    },
  },
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({
          lsp_fallback = true,
          async = false,
          timeout_ms = 500,
        })
      end,
      desc = "Code Format"
    },
  },
}
