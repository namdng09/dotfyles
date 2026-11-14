# CLAUDE.md

Dotfiles cá nhân, quản lý bằng **GNU stow**. Dùng trên Arch (WSL2), Ubuntu và macOS.

## Cấu trúc

Mỗi thư mục cấp 1 là một **package stow phẳng**: file nằm thẳng trong thư mục, không lồng `.config/…`.
Đích của từng package khai báo trong hàm `target()` của `install.sh`:

| Package | Đích | Ghi chú |
|---|---|---|
| `nvim` | `~/.config/nvim` | LazyVim |
| `tmux` | `~/.config/tmux` | `tmux/plugins/` do TPM tải về, đã gitignore |
| `fish` | `~/.config/fish` | chỉ `config.fish`; **không** đưa `fish_variables` vào repo (fish tự ghi, khác nhau giữa các máy) |
| `starship` | `~/.config` | `starship.toml` là **symlink** tới theme đang dùng |
| `kitty`, `alacritty`, `kanata`, `zmk` | `~/.config/<tên>` | kanata trên WSL: `windows.kbd` được **chép** (không link) sang `%APPDATA%\kanata\kanata.kbd` cho kanata phía Windows |
| `claude` | `~/.claude` | chỉ `statusline.sh`; `settings.json` **không** stow vì Claude Code tự ghi lại, `install.sh` chèn `statusLine` bằng jq |

Starship: theme đang dùng = file mà `starship/starship.toml` trỏ tới (hiện là `catppuccin-powerline.toml`;
`default.toml` là theme cũ). Đổi theme bằng `ln -sfn <theme>.toml starship/starship.toml`.
Không bao giờ dùng `starship preset … -o ~/.config/starship.toml`, vì lệnh đó ghi đè symlink bằng file thường.

## install.sh

- `./install.sh`: menu checkbox → cài công cụ (brew / `pacman -Syu --needed` / apt) → stow.
  File thật đang chặn stow được đổi tên thành `*.bak.<thời gian>`, không bị xoá.
- `./install.sh <pkg>…`, `-D`, `-R`: chế độ cũ, chỉ stow, không cài công cụ.
  Không cờ hoặc `-R` cũng sao lưu file thật thành `*.bak.<thời gian>` như menu; `-D` và cờ khác chuyển thẳng cho stow.
- `--defaults` (không menu), `--dry-run` (chỉ in lệnh).

Thêm package mới: thêm vào `target()`, thêm một dòng vào `ITEMS` (`id|mặc định|mô tả`), thêm gói vào `deps()` cho từng trình quản lý gói.

### Ràng buộc

- **Phải chạy được với bash 3.2** (mặc định trên macOS): không `declare -A`, `mapfile`, `${x,,}`, `read -N`, `read -t` số lẻ.
  Mảng rỗng dưới `set -u` thì mở rộng bằng `${arr[@]+"${arr[@]}"}`.
- Biến đứng sát ký tự không phải ASCII (`❯`, `→`, chữ có dấu…) phải viết `${var}`: bash 3.2 đọc các byte UTF-8 thành một phần tên biến → `unbound variable`.
- Script dùng `set -e`: không viết `((x = …))` đứng một mình vì kết quả bằng 0 sẽ thoát script, dùng `x=$(( … ))`.
- Arch: luôn `pacman -Syu`, không `-Sy`/`-S` riêng (database cũ → lỗi 404 file `.sig`, hoặc nâng cấp nửa vời).
- Config phải chạy được trên cả Linux và macOS: kiểm tra công cụ trước khi dùng (`type -q` trong fish, `command -v` trong bash),
  đường dẫn Homebrew `/opt/homebrew` (Apple Silicon) và `/usr/local` (Intel), phần riêng cho WSL bọc trong `set -q WSL_DISTRO_NAME`.

## Kiểm tra thay đổi

```bash
bash -n install.sh && fish -n fish/config.fish
./install.sh --defaults --dry-run
# chạy thật trên HOME giả, không cài gì vào máy:
mkdir -p /tmp/fakehome && HOME=/tmp/fakehome ./install.sh --defaults --dry-run
```

Không chạy `./install.sh` thật (không có `--dry-run`) trên máy người dùng khi chưa được đồng ý, vì nó gọi `sudo` và có thể đổi tên file config.

## Quy ước

- Trả lời người dùng bằng **tiếng Việt**. Comment trong script cũng viết tiếng Việt, theo đúng kiểu đang có.
- Commit message bằng tiếng Anh, theo Conventional Commits có scope: `feat(starship): …`, `fix(nvim): …`.
- Nhánh chính là `develop`.
