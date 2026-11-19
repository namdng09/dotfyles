-- Ctrl+h/j/k/l: chuyển split của nvim, tới mép thì chuyển sang pane bên cạnh của tmux hoặc herdr.
-- - Trong tmux: dùng vim-tmux-navigator như cũ.
-- - Trong herdr (HERDR_ENV=1): herdr chuyển phím Ctrl+h/j/k/l cho nvim (herdr/nav.sh);
--   nvim đổi split, nếu không còn split theo hướng đó thì gọi `herdr pane focus`.
-- - Ngoài cả hai: chỉ đổi split.
local M = {}

local herdr_dir = { h = "left", j = "down", k = "up", l = "right" }
local tmux_cmd = { h = "TmuxNavigateLeft", j = "TmuxNavigateDown", k = "TmuxNavigateUp", l = "TmuxNavigateRight" }

function M.go(key)
  if vim.env.TMUX then
    vim.cmd(tmux_cmd[key])
    return
  end
  local win = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. key)
  if win == vim.api.nvim_get_current_win() and vim.env.HERDR_ENV == "1" then
    -- --current: pane đang chạy nvim này (theo HERDR_PANE_ID)
    vim.system({ vim.env.HERDR_BIN_PATH or "herdr", "pane", "focus", "--current", "--direction", herdr_dir[key] })
  end
end

return M
