# macOS: Homebrew (Apple Silicon /opt/homebrew, Intel /usr/local) — fish không đọc ~/.zprofile
for brew in /opt/homebrew/bin/brew /usr/local/bin/brew
    if test -x $brew
        $brew shellenv | source
        break
    end
end
fish_add_path ~/.local/bin ~/.opencode/bin
set -g fish_greeting

# macOS qua SSH: client không gửi LANG → locale "C", tmux/nvim hiện sai ký tự Unicode
if test (uname) = Darwin; and not string match -qi '*utf*' -- "$LC_ALL$LC_CTYPE$LANG"
    set -gx LANG en_US.UTF-8
end

# Chỉ trên WSL: mở link bằng trình duyệt của Windows
if set -q WSL_DISTRO_NAME
    set -gx BROWSER wsl-open
end

if status is-interactive
    # TERM của client (xterm-kitty, alacritty…) không có terminfo trên máy này → dùng xterm-256color
    if set -q SSH_TTY; and not infocmp $TERM >/dev/null 2>&1
        set -gx TERM xterm-256color
    end

    type -q zoxide; and zoxide init fish | source
    type -q starship; and starship init fish | source

    type -q eza; and alias ls 'eza --icons'
    alias tailscale /Applications/Tailscale.app/Contents/MacOS/Tailscale
    alias cls clear
    alias vi nvim
end
