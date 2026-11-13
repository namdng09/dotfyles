# install package by pacman
- sudo pacman -S fcitx5 fcitx5-gtk fcitx5-qt fcitx5-im fcitx5-configtool fcitx5-unikey fcitx5-mozc

#input method
#setup
exec-once = export GTK_IM_MODULE=fcitx5
exec-once = export QT_IM_MODULE=fcitx5
exec-once = export XMODIFIERS=@im=fcitx5
exec-once = export INPUT_METHOD=fcitx5
exec-once = export SDL_IM_MODULE=fcitx5
#auto start
exec-once = fcitx5
