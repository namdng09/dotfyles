return {
  "akinsho/flutter-tools.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "stevearc/dressing.nvim" },
  config = function()
    require("flutter-tools").setup({
      hot_reload_on_save = true,
      lsp = {
        on_attach = function(client, bufnr)
          -- your custom mappings here
        end,
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
      },
    })
  end,
}
