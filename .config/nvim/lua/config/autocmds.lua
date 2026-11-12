-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- show cursor line only in active window
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "typescript" },
  callback = function()
    vim.bo.smartindent = true
  end,
})
vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, {
  callback = function()
    if vim.w.auto_cursorline then
      vim.wo.cursorline = true
      vim.w.auto_cursorline = nil
    end
  end,
})
vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave" }, {
  callback = function()
    if vim.wo.cursorline then
      vim.w.auto_cursorline = true
      vim.wo.cursorline = false
    end
  end,
})

-- Only insert mode is allowed to use non-English input methods.
if vim.fn.executable("fcitx5-remote") == 1 then
  local english_im = "keyboard-us"

  local function set_fcitx_im(im)
    if im and im ~= "" then
      vim.fn.system({ "fcitx5-remote", "-s", im })
    end
  end

  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      set_fcitx_im(english_im)
    end,
  })

  vim.api.nvim_create_autocmd({ "FocusGained", "WinEnter", "BufEnter" }, {
    callback = function()
      if vim.fn.mode() ~= "i" then
        set_fcitx_im(english_im)
      end
    end,
  })

  vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function()
      set_fcitx_im(english_im)
    end,
  })
end

-- backups
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("better_backup", { clear = true }),
  callback = function(event)
    local file = vim.uv.fs_realpath(event.match) or event.match
    local backup = vim.fn.fnamemodify(file, ":p:~:h")
    backup = backup:gsub("[/\\]", "%%")
    vim.go.backupext = backup
  end,
})

vim.filetype.add({
  extension = {
    overlay = "dts",
    keymap = "dts",
  },
})

vim.api.nvim_create_autocmd("QuickFixCmdPost", {
  callback = function()
    vim.cmd([[Trouble qflist open]])
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "json",
  callback = function()
    vim.bo.formatexpr = ""
    vim.bo.formatprg = "jq"
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "json",
  callback = function()
    vim.bo.formatexpr = ""
    vim.bo.formatprg = "jq"
  end,
})
-- Setup our JDTLS server any time we open up a java file
-- vim.cmd [[
--     augroup jdtls_lsp
--         autocmd!
--         autocmd FileType java lua require'config.jdtls'.setup_jdtls()
--     augroup end
-- ]]
