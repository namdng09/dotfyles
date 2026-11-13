# macOS: Homebrew (Apple Silicon /opt/homebrew, Intel /usr/local) — fish không đọc ~/.zprofile
for brew in /opt/homebrew/bin/brew /usr/local/bin/brew
    if test -x $brew
        $brew shellenv | source
        break
    end
end
fish_add_path ~/.local/bin ~/.opencode/bin
set -g fish_greeting

# Chỉ trên WSL: mở link bằng trình duyệt của Windows
if set -q WSL_DISTRO_NAME
    set -gx BROWSER wsl-open
end

if status is-interactive
    type -q zoxide; and zoxide init fish | source
    type -q starship; and starship init fish | source

    type -q eza; and alias ls 'eza --icons'
    alias cls clear
    alias vi nvim
end
