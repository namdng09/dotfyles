#!/usr/bin/env bash
# Trình cài dotfiles: chọn bằng checkbox -> cài công cụ (brew/pacman/apt) -> stow config.
#   ./install.sh                 → menu checkbox (↑/↓ hoặc j/k, Space chọn, a: tất cả, n: bỏ hết, Enter: cài, q: thoát)
#   ./install.sh --defaults      → cài các mục mặc định, không hiện menu
#   ./install.sh --dry-run       → chỉ in ra lệnh sẽ chạy (kết hợp được với --defaults)
#   ./install.sh kitty kanata    → CHỈ stow các package chỉ định (không cài công cụ)
#   ./install.sh -D nvim         → gỡ link (-R: stow lại)
# Chạy được với bash 3.2 mặc định của macOS (không dùng declare -A, mapfile, ${x,,}).
set -euo pipefail
cd "$(dirname "$0")"

# ───────────────────────── tiện ích ─────────────────────────
c_bold=$'\e[1m'; c_dim=$'\e[2m'; c_grn=$'\e[32m'; c_ylw=$'\e[33m'; c_red=$'\e[31m'; c_cyn=$'\e[36m'; c_off=$'\e[0m'
say()  { printf '%s==>%s %s\n' "$c_cyn$c_bold" "$c_off" "$*"; }
warn() { printf '%s!!%s  %s\n' "$c_ylw$c_bold" "$c_off" "$*" >&2; WARNINGS+=("$*"); }
die()  { printf '%sxx%s  %s\n' "$c_red$c_bold" "$c_off" "$*" >&2; exit 1; }
DRY=0
run()  { if [[ $DRY == 1 ]]; then printf '%s  $ %s%s\n' "$c_dim" "$*" "$c_off"; else "$@"; fi; }
WARNINGS=()

target() {
  case $1 in
    nvim)      echo "$HOME/.config/nvim" ;;
    tmux)      echo "$HOME/.config/tmux" ;;
    starship)  echo "$HOME/.config" ;;
    fish)      echo "$HOME/.config/fish" ;;
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
  command -v jq >/dev/null || { warn "Thiếu jq: tự thêm statusLine vào $f"; return; }
  [[ $DRY == 1 ]] && { run jq '.statusLine = {...}' "$f"; return; }
  [[ -f $f ]] || echo '{}' > "$f"
  jq '.statusLine = {type: "command", command: "~/.claude/statusline.sh", padding: 0}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  echo "claude: đã bật statusLine trong $f"
}

# Trên WSL, kanata chạy phía Windows. Chép windows.kbd sang %APPDATA%\kanata\kanata.kbd
# (không cho Windows đọc qua \\wsl$ vì lúc khởi động máy WSL chưa chạy).
setup_kanata_windows() {
  grep -qi microsoft /proc/version 2>/dev/null || return 0
  command -v cmd.exe >/dev/null && command -v wslpath >/dev/null \
    || { warn "Không gọi được cmd.exe/wslpath: tự chép kanata/windows.kbd sang %APPDATA%\\kanata\\kanata.kbd"; return 0; }
  local appdata dir
  appdata=$(cd /mnt/c && cmd.exe /c 'echo %APPDATA%' 2>/dev/null | tr -d '\r') || true
  [[ -n $appdata && $appdata != '%APPDATA%' ]] \
    || { warn "Không đọc được %APPDATA% của Windows: tự chép kanata/windows.kbd"; return 0; }
  dir="$(wslpath -u "$appdata")/kanata"
  say "kanata (Windows): chép windows.kbd → ${dir}/kanata.kbd"
  run mkdir -p "$dir"
  run cp kanata/windows.kbd "$dir/kanata.kbd"
  check_kanata_windows "${dir%/AppData/Roaming/kanata}" "$appdata\\kanata\\kanata.kbd"
}

# Kiểm tra cú pháp config bằng kanata.exe của Windows. Bản gui không báo lỗi khi reload
# (đã tắt notify-error), nên config lỗi sẽ bị bỏ qua âm thầm; kiểm tra ở đây để biết ngay.
# Tìm exe: biến KANATA_EXE, rồi C:\Tools\kanata, Downloads của Windows, <ổ>:\Downloads. Ưu tiên bản tty (in ra lỗi).
check_kanata_windows() {
  local win_home=$1 cfg=$2 exe="${KANATA_EXE:-}" d out
  if [[ -z $exe ]]; then
    for d in /mnt/c/Tools/kanata "$win_home/Downloads" /mnt/?/Downloads "$win_home/AppData/Local/Programs"; do
      [[ -d $d ]] || continue
      exe=$(find "$d" -maxdepth 2 -iname 'kanata*tty*.exe' 2>/dev/null | head -n1)
      [[ -z $exe ]] && exe=$(find "$d" -maxdepth 2 -iname 'kanata*.exe' 2>/dev/null | head -n1)
      [[ -n $exe ]] && break
    done
  fi
  if [[ -z $exe ]]; then
    warn "Không tìm thấy kanata.exe để kiểm tra config (đặt KANATA_EXE=/mnt/c/…/kanata.exe để chỉ định)"
    return 0
  fi
  if [[ $DRY == 1 ]]; then run "$exe" --check --cfg "$cfg"; return 0; fi
  if out=$(cd /mnt/c && "$exe" --check --cfg "$cfg" 2>&1); then
    say "kanata (Windows): config hợp lệ (${exe##*/}). Bấm lrld hoặc Reload ở icon khay để nạp."
  else
    printf '%s\n' "$out" | tr -d '\r' | sed 's/\x1b\[[0-9;]*m//g' | grep -v '\[INFO\]' >&2 || true
    warn "kanata (Windows): config LỖI, kanata sẽ giữ bản cũ khi reload. Sửa kanata/windows.kbd rồi chạy lại."
  fi
}

# Chuyển file thật đang chặn stow sang *.bak.<thời gian> rồi stow lại (chạy lại nhiều lần vẫn an toàn).
stow_pkg() {
  local p=$1 t f conflicts
  t=$(target "$p")
  [[ -z $t ]] && die "Không biết đích của package '$p' (thêm vào target())"
  run mkdir -p "$t"
  # stow cũ: "existing target is neither a link nor a directory: X"; stow mới: "over existing target X since ..."
  conflicts=$(stow -n -t "$t" "$p" 2>&1 | sed -n \
    -e 's/.*existing target is [^:]*: \(.*\)$/\1/p' \
    -e 's/.*over existing target \([^ ]*\) since.*/\1/p' || true)
  if [[ -n $conflicts ]]; then
    while IFS= read -r f; do
      [[ -z $f ]] && continue
      say "Sao lưu $t/$f → $f.bak.$STAMP"
      run mv "$t/$f" "$t/$f.bak.$STAMP"
    done <<< "$conflicts"
  fi
  run stow -v -R -t "$t" "$p"
  [[ $p == claude ]] && setup_claude
  [[ $p == kanata ]] && setup_kanata_windows
  return 0
}

# ─────────────────────── chế độ cũ: chỉ stow ───────────────────────
flags=(); MODE=menu
while [[ $# -gt 0 && $1 == -* ]]; do
  case $1 in
    --defaults) MODE=defaults ;;
    --dry-run)  DRY=1 ;;
    -h|--help)  sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)          flags+=("$1") ;;
  esac
  shift
done
STAMP=$(date +%Y%m%d-%H%M%S)

if [[ $# -gt 0 || ${#flags[@]} -gt 0 ]]; then
  command -v stow >/dev/null || die "Thiếu GNU stow (macOS: brew install stow, Arch: sudo pacman -S stow, Ubuntu: sudo apt install stow)"
  [[ $# -gt 0 ]] && packages=("$@") || packages=(nvim tmux starship fish)
  for p in "${packages[@]}"; do
    # Không cờ hoặc chỉ -R: stow_pkg (sao lưu file thật đang chặn); cờ khác (-D…) chuyển thẳng cho stow
    case " ${flags[*]-} " in
      "  "|" -R ") stow_pkg "$p"; continue ;;
    esac
    t=$(target "$p")
    [[ -z $t ]] && die "Không biết đích của package '$p' (thêm vào target())"
    mkdir -p "$t"
    # ${flags[@]+...}: bash 3.2 với set -u báo lỗi khi mở rộng mảng rỗng
    stow -v ${flags[@]+"${flags[@]}"} -t "$t" "$p"
    if [[ $p == claude && " ${flags[*]-} " != *" -D "* ]]; then setup_claude; fi
  done
  exit 0
fi

# ───────────────────────── phát hiện hệ thống ─────────────────────────
OS=$(uname -s); WSL=0
grep -qi microsoft /proc/version 2>/dev/null && WSL=1
if [[ $OS == Darwin ]]; then
  PM=brew
  # Homebrew Apple Silicon / Intel chưa có trong PATH (shell mới cài)
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    command -v brew >/dev/null || { [[ -x $b ]] && eval "$("$b" shellenv)"; }
  done
elif command -v pacman >/dev/null; then PM=pacman
elif command -v apt-get >/dev/null; then PM=apt
else PM=none
fi

# ───────────────────────── danh sách mục ─────────────────────────
# id | mặc định (1/0) | mô tả.  Package stow = id (trừ font, chsh).
ITEMS=(
  "nvim|1|Neovim (LazyVim) + ripgrep, fd, lazygit, node"
  "tmux|1|tmux (plugin TPM tự tải lần đầu mở tmux)"
  "fish|1|fish shell + zoxide, eza"
  "starship|1|Starship prompt (theme catppuccin-powerline)"
  "font|1|Nerd Fonts: JetBrainsMono, FiraCode, CaskaydiaMono, Symbols"
  "chsh|0|Đặt fish làm shell mặc định (chsh)"
  "kitty|0|kitty terminal + config"
  "alacritty|0|Alacritty terminal + config"
  "claude|0|Claude Code status line (cần jq)"
  "kanata|0|Kanata (bàn phím home-row mods) — chỉ link config (WSL: chép thêm windows.kbd sang Windows)"
  "zmk|0|ZMK keymap (Corne) — chỉ link config"
)
# Trên WSL font/terminal phải cài phía Windows
if [[ $WSL == 1 ]]; then
  ITEMS[4]="font|0|Nerd Fonts (WSL: cài font trên Windows thay vì ở đây)"
fi
N=${#ITEMS[@]}
id_of()   { local s=${ITEMS[$1]}; echo "${s%%|*}"; }
desc_of() { local s=${ITEMS[$1]}; echo "${s##*|}"; }
SEL=(); for ((i = 0; i < N; i++)); do s=${ITEMS[$i]#*|}; SEL[i]=${s%%|*}; done

# Gói cần cài cho từng mục, theo trình quản lý gói. "cask:" = brew --cask.
deps() {
  case "$PM:$1" in
    brew:nvim)       echo "neovim ripgrep fd lazygit node" ;;
    brew:tmux)       echo "tmux" ;;
    brew:fish|brew:chsh) echo "fish zoxide eza" ;;
    brew:starship)   echo "starship" ;;
    brew:font)       echo "cask:font-jetbrains-mono-nerd-font cask:font-fira-code-nerd-font cask:font-caskaydia-mono-nerd-font cask:font-symbols-only-nerd-font" ;;
    brew:kitty)      echo "cask:kitty" ;;
    brew:alacritty)  echo "cask:alacritty" ;;
    brew:claude)     echo "jq" ;;
    pacman:nvim)     echo "neovim ripgrep fd lazygit nodejs npm" ;;
    pacman:tmux)     echo "tmux" ;;
    pacman:fish|pacman:chsh) echo "fish zoxide eza" ;;
    pacman:starship) echo "starship" ;;
    pacman:font)     echo "ttf-jetbrains-mono-nerd ttf-firacode-nerd ttf-cascadia-mono-nerd ttf-nerd-fonts-symbols" ;;
    pacman:kitty)    echo "kitty" ;;
    pacman:alacritty) echo "alacritty" ;;
    pacman:claude)   echo "jq" ;;
    apt:nvim)        echo "neovim ripgrep fd-find nodejs npm" ;;
    apt:tmux)        echo "tmux" ;;
    apt:fish|apt:chsh) echo "fish zoxide eza" ;;
    apt:starship)    echo "starship" ;;
    apt:kitty)       echo "kitty" ;;
    apt:alacritty)   echo "alacritty" ;;
    apt:claude)      echo "jq" ;;
  esac
}

# ───────────────────────── menu checkbox ─────────────────────────
draw() {
  local i mark ptr
  printf '\e[H\e[2J'
  printf '%sdotfyles installer%s  %s(%s · %s%s)%s\n\n' "$c_bold" "$c_off" "$c_dim" "$OS" "$PM" "$([[ $WSL == 1 ]] && echo ' · WSL')" "$c_off"
  for ((i = 0; i < N; i++)); do
    [[ ${SEL[i]} == 1 ]] && mark="$c_grn[x]$c_off" || mark="[ ]"
    [[ $i == "$CUR" ]] && ptr="${c_cyn}❯${c_off}" || ptr=" "
    printf ' %s %s %-10s %s%s%s\n' "$ptr" "$mark" "$(id_of "$i")" "$c_dim" "$(desc_of "$i")" "$c_off"
  done
  printf '\n%s↑/↓ j/k di chuyển · Space chọn · a tất cả · n bỏ hết · Enter cài · q thoát%s\n' "$c_dim" "$c_off"
}

menu() {
  local key rest i
  CUR=0
  printf '\e[?25l'; trap 'printf "\e[?25h"' EXIT
  while true; do
    draw
    IFS= read -rsn1 key </dev/tty
    case $key in
      $'\e') IFS= read -rsn2 rest </dev/tty || true
             case $rest in '[A') CUR=$(( (CUR - 1 + N) % N )) ;; '[B') CUR=$(( (CUR + 1) % N )) ;; esac ;;
      k) CUR=$(( (CUR - 1 + N) % N )) ;;
      j) CUR=$(( (CUR + 1) % N )) ;;
      ' ') [[ ${SEL[CUR]} == 1 ]] && SEL[CUR]=0 || SEL[CUR]=1 ;;
      a) for ((i = 0; i < N; i++)); do SEL[i]=1; done ;;
      n) for ((i = 0; i < N; i++)); do SEL[i]=0; done ;;
      q) printf '\e[?25h\n'; exit 0 ;;
      '') break ;;
    esac
  done
  printf '\e[?25h'
}

if [[ $MODE == menu ]]; then
  [[ -t 0 && -t 1 ]] || die "Không có terminal để hiện menu — dùng ./install.sh --defaults"
  menu
fi

CHOSEN=(); for ((i = 0; i < N; i++)); do [[ ${SEL[i]} == 1 ]] && CHOSEN+=("$(id_of "$i")"); done
[[ ${#CHOSEN[@]} -eq 0 ]] && { echo "Không chọn gì, thoát."; exit 0; }
echo; say "Sẽ cài: ${CHOSEN[*]}"
if [[ $MODE == menu && $DRY == 0 ]]; then
  printf 'Tiếp tục? [Y/n] '; read -r ans </dev/tty
  case $ans in n|N|no|NO) exit 0 ;; esac
fi
has() { local x; for x in "${CHOSEN[@]}"; do [[ $x == "$1" ]] && return 0; done; return 1; }

# ───────────────────────── cài công cụ ─────────────────────────
ensure_brew() {
  command -v brew >/dev/null && return
  say "Chưa có Homebrew. Lệnh cài chính thức:"
  echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  printf 'Cài Homebrew ngay? [y/N] '; read -r ans </dev/tty
  [[ $ans == y || $ans == Y ]] || die "Cần Homebrew để cài công cụ trên macOS"
  run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [[ -x $b ]] && eval "$("$b" shellenv)" && break; done
}

PKGS="git stow"
for x in "${CHOSEN[@]}"; do d=$(deps "$x"); [[ -n $d ]] && PKGS="$PKGS $d"; done
# bỏ trùng, giữ thứ tự
PKGS=$(printf '%s\n' $PKGS | awk '!seen[$0]++' | tr '\n' ' ')

case $PM in
  brew)
    [[ $DRY == 1 ]] || ensure_brew
    say "Homebrew: $PKGS"
    for p in $PKGS; do
      if [[ $p == cask:* ]]; then
        p=${p#cask:}
        brew list --cask "$p" >/dev/null 2>&1 || run brew install --cask "$p" || warn "brew: không cài được cask $p"
      else
        brew list --formula "$p" >/dev/null 2>&1 || run brew install "$p" || warn "brew: không cài được $p"
      fi
    done ;;
  pacman)
    # -Syu cùng lúc: tránh lỗi 404 khi database cũ và tránh nâng cấp nửa vời
    say "pacman: $PKGS"
    run sudo pacman -Syu --needed $PKGS || warn "pacman báo lỗi, xem log ở trên" ;;
  apt)
    say "apt: $PKGS"
    run sudo apt-get update
    for p in $PKGS; do
      dpkg -s "$p" >/dev/null 2>&1 || run sudo apt-get install -y "$p" || warn "apt: không có gói $p (cài tay)"
    done
    has font && warn "apt: không có Nerd Fonts, tải ở https://www.nerdfonts.com/font-downloads" ;;
  none)
    warn "Không nhận ra trình quản lý gói, tự cài: $PKGS" ;;
esac

command -v stow >/dev/null || [[ $DRY == 1 ]] || die "Vẫn chưa có stow, không link config được"

# ───────────────────────── link config ─────────────────────────
for x in "${CHOSEN[@]}"; do
  case $x in
    font|chsh) ;;
    *) say "stow $x → $(target "$x")"; stow_pkg "$x" ;;
  esac
done
has kanata && [[ $OS == Darwin ]] && warn "kanata trên macOS cần driver Karabiner-DriverKit-VirtualHIDDevice (xem kanata/config.adoc)"

# ───────────────────────── shell mặc định ─────────────────────────
if has chsh; then
  fish_bin=$(command -v fish || true)
  if [[ -z $fish_bin ]]; then
    warn "Chưa có fish, bỏ qua chsh"
  elif [[ ${SHELL:-} == "$fish_bin" ]]; then
    say "fish đã là shell mặc định"
  else
    grep -qx "$fish_bin" /etc/shells || run sudo sh -c "echo '$fish_bin' >> /etc/shells"
    run chsh -s "$fish_bin" || warn "chsh thất bại, chạy tay: chsh -s $fish_bin"
  fi
fi

echo
say "Xong. Mở terminal mới (hoặc: exec fish) để nạp config."
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  printf '\n%sCần xem lại:%s\n' "$c_ylw$c_bold" "$c_off"
  for w in "${WARNINGS[@]}"; do echo "  - $w"; done
fi
