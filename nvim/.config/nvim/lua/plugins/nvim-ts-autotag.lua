return {
  "windwp/nvim-ts-autotag",      -- tên repo đầy đủ
  opts = {
    -- bảng này sẽ được truyền nguyên vào require("nvim-ts-autotag").setup(...)
    opts = {                     -- các tuỳ chọn chung
      enable_close = true,       -- Tự đóng thẻ
      enable_rename = true,      -- Tự đổi tên cặp thẻ
      enable_close_on_slash = false, -- Tự đóng khi gõ "</"
    },
    -- cấu hình riêng cho từng filetype
    per_filetype = {
      -- html = {                   -- trong HTML muốn tắt auto-close
      --   enable_close = false,
      -- },
    },
  },
  -- (tuỳ chọn) lazy-loading
  -- event = { "BufReadPre", "BufNewFile" },
}
