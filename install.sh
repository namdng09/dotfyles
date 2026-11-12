#!/usr/bin/env bash
# Stow từng package vào đúng thư mục đích (mỗi package để phẳng, không lồng .config/).
#   ./install.sh                 → stow nvim, tmux, starship
#   ./install.sh kitty kanata    → stow các package chỉ định
#   ./install.sh claude          → status line Claude Code (cần jq)
#   ./install.sh -D nvim         → gỡ link (-R: stow lại)
# Chạy được với bash 3.2 mặc định của macOS (không dùng declare -A).
set -euo pipefail
cd "$(dirname "$0")"

target() {
  case $1 in
    nvim)      echo "$HOME/.config/nvim" ;;
    tmux)      echo "$HOME/.config/tmux" ;;
    starship)  echo "$HOME/.config" ;;
    kitty)     echo "$HOME/.config/kitty" ;;
    alacritty) echo "$HOME/.config/alacritty" ;;
    kanata)    echo "$HOME/.config/kanata" ;;
    zmk)       echo "$HOME/.config/zmk" ;;
    claude)    echo "$HOME/.claude" ;;
  esac
}

# Claude Code tự ghi lại settings.json (đổi model, theme…) nên không stow file đó,
# chỉ chèn mục statusLine trỏ tới statusline.sh đã stow.
setup_claude() {
  local f="$HOME/.claude/settings.json"
  command -v jq >/dev/null || { echo "Thiếu jq: tự thêm statusLine vào $f"; return; }
  [[ -f $f ]] || echo '{}' > "$f"
  jq '.statusLine = {type: "command", command: "~/.claude/statusline.sh", padding: 0}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  echo "claude: đã bật statusLine trong $f"
}

command -v stow >/dev/null || { echo "Thiếu GNU stow (Ubuntu: sudo apt install stow, macOS: brew install stow)"; exit 1; }

flags=()
while [[ $# -gt 0 && $1 == -* ]]; do flags+=("$1"); shift; done
if [[ $# -gt 0 ]]; then packages=("$@"); else packages=(nvim tmux starship); fi

for p in "${packages[@]}"; do
  t=$(target "$p")
  [[ -z $t ]] && { echo "Không biết đích của package '$p' (thêm vào target())"; exit 1; }
  mkdir -p "$t"
  # ${flags[@]+...}: bash 3.2 với set -u báo lỗi khi mở rộng mảng rỗng
  stow -v ${flags[@]+"${flags[@]}"} -t "$t" "$p"
  if [[ $p == claude && " ${flags[*]-} " != *" -D "* ]]; then setup_claude; fi
done
