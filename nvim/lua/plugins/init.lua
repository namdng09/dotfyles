return {
  "nvim-lua/plenary.nvim", -- lua functions that many plugins use
  {
    -- Tách thành spec riêng: trước đây cmd/keys nằm chung bảng với plenary nên lazy.nvim bỏ qua,
    -- và vim-tmux-navigator tự gán phím mặc định của nó.
    "christoomey/vim-tmux-navigator", -- tmux & split window navigation
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    init = function()
      -- Không cho plugin tự gán Ctrl+h/j/k/l, dùng phím bên dưới
      vim.g.tmux_navigator_no_mappings = 1
    end,
    -- Ctrl+h/j/k/l: split của nvim → pane tmux hoặc herdr (xem lua/config/navigate.lua)
    keys = {
      { "<C-h>", function() require("config.navigate").go("h") end, desc = "Go to left split/pane" },
      { "<C-j>", function() require("config.navigate").go("j") end, desc = "Go to lower split/pane" },
      { "<C-k>", function() require("config.navigate").go("k") end, desc = "Go to upper split/pane" },
      { "<C-l>", function() require("config.navigate").go("l") end, desc = "Go to right split/pane" },
      { "<C-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", desc = "Go to previous tmux pane" },
    },
  },
}
