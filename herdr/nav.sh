#!/bin/sh
# Ctrl+h/j/k/l trong herdr (gắn ở config.toml, [[keys.command]]).
# Pane đang focus chạy nvim/vim → chuyển phím cho nvim: nvim đổi split, tới mép thì tự gọi
# `herdr pane focus` (xem nvim/lua/config/navigate.lua). Pane khác → herdr chuyển sang pane bên cạnh.
dir=$1
case $dir in
  left) key=ctrl+h ;; down) key=ctrl+j ;; up) key=ctrl+k ;; right) key=ctrl+l ;;
  *) echo "dùng: nav.sh left|down|up|right" >&2; exit 2 ;;
esac
herdr=${HERDR_BIN_PATH:-herdr}
# Không lấy pane đang chạy lệnh này, mà lấy pane đang focus trên UI
unset HERDR_PANE_ID

if ! command -v jq >/dev/null 2>&1; then
  exec "$herdr" pane focus --direction "$dir"
fi
pane=$("$herdr" pane current | jq -r '.result.pane.pane_id') || exit 1
procs=$("$herdr" pane process-info --pane "$pane" | jq -r '[.result.process_info.foreground_processes[].name] | join(" ")')
case " $procs " in
  *" nvim "* | *" vim "* | *" vi "*) exec "$herdr" pane send-keys "$pane" "$key" ;;
  *) exec "$herdr" pane focus --pane "$pane" --direction "$dir" ;;
esac
