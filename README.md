# dotfyles
all my config for nvim, tmux, fish, starship, kitty, alacritty, kanata, zmk…  
Chạy được trên macOS (Homebrew), Arch (pacman), Ubuntu/Debian (apt) và WSL.

## Cài trên máy mới

```bash
git clone https://github.com/namdng09/dotfyles.git ~/dotfyles
cd ~/dotfyles
./install.sh
```

`install.sh` hiện menu checkbox để chọn mục cần cài:

| Phím | Tác dụng |
|---|---|
| `↑` `↓` / `j` `k` | di chuyển |
| `Space` | chọn / bỏ chọn |
| `a` / `n` | chọn tất cả / bỏ hết |
| `Enter` | cài |
| `q` | thoát |

Mỗi mục sẽ: cài công cụ cần thiết (brew/pacman/apt) → link config bằng GNU stow.
File config có sẵn trên máy bị trùng sẽ được đổi tên thành `*.bak.<thời gian>` chứ không bị xoá.
Chạy lại bao nhiêu lần cũng được.

```bash
./install.sh --defaults        # cài mục mặc định, không hiện menu
./install.sh --dry-run         # chỉ in lệnh sẽ chạy
./install.sh fish nvim         # chỉ link config (không cài công cụ)
./install.sh -D nvim           # gỡ link   (-R: link lại)
```

Sau khi cài, sửa file trong `~/dotfyles` là config cập nhật theo (đều là symlink).

## Starship

Theme đang dùng = file mà `starship/starship.toml` trỏ tới:

```bash
ln -sfn gruvbox-rainbow.toml ~/dotfyles/starship/starship.toml       # đổi theme
```

Đừng chạy `starship preset … -o ~/.config/starship.toml`: lệnh đó ghi đè symlink.
