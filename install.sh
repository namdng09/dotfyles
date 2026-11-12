#!/usr/bin/env bash
# Stow từng package vào đúng thư mục đích (mỗi package để phẳng, không lồng .config/).
#   ./install.sh                 → stow nvim, tmux, starship
#   ./install.sh kitty kanata    → stow các package chỉ định
#   ./install.sh -D nvim         → gỡ link (-R: stow lại)
set -euo pipefail
cd "$(dirname "$0")"

declare -A TARGET=(
  [nvim]="$HOME/.config/nvim"
  [tmux]="$HOME/.config/tmux"
  [starship]="$HOME/.config"
  [kitty]="$HOME/.config/kitty"
  [alacritty]="$HOME/.config/alacritty"
  [kanata]="$HOME/.config/kanata"
  [zmk]="$HOME/.config/zmk"
)

flags=()
while [[ $# -gt 0 && $1 == -* ]]; do flags+=("$1"); shift; done
packages=("$@")
[[ ${#packages[@]} -eq 0 ]] && packages=(nvim tmux starship)

for p in "${packages[@]}"; do
  t=${TARGET[$p]:-}
  [[ -z $t ]] && { echo "Không biết đích của package '$p' (thêm vào TARGET)"; exit 1; }
  mkdir -p "$t"
  stow -v "${flags[@]}" -t "$t" "$p"
done
