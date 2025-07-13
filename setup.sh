#!/bin/bash
set -e

echo "==> Syncing time and updating system..."
sudo timedatectl set-ntp true
sudo pacman -Syu --noconfirm

echo "==> Installing base packages..."
sudo pacman -S --needed --noconfirm $(< packages.txt)

# === Install yay if not present ===
if ! command -v yay &>/dev/null; then
  echo "==> Installing yay from AUR..."
  sudo pacman -S --needed --noconfirm git base-devel
  cd /tmp
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
fi


echo "==> Copying dotfiles..."
cp -r dotfiles/.config/* ~/.config/
cp dotfiles/.xinitrc ~/

echo "==> Setting GTK theme..."
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
cp -r dotfiles/.config/gtk-3.0/* ~/.config/gtk-3.0/
cp -r dotfiles/.config/gtk-4.0/* ~/.config/gtk-4.0/

echo "==> Installing resolution fix script..."
mkdir -p ~/.config/scripts
cp dotfiles/.config/scripts/set-resolution.sh ~/.config/scripts/
chmod +x ~/.config/scripts/set-resolution.sh

echo "==> Installing Rofi themes..."
mkdir -p ~/.local/share/rofi/themes
cp themes/*.rasi ~/.local/share/rofi/themes/

echo "==> Applying default Rofi theme..."
mkdir -p ~/.config/rofi
echo '@import "~/.local/share/rofi/themes/nord.rasi"' > ~/.config/rofi/config.rasi

echo "==> Setting wallpaper..."
feh --bg-scale ~/.config/wallpapers/beautiful-mountains.jpg

echo "==> Enabling VMware tools..."
sudo systemctl enable vmtoolsd.service

echo "==> Setup complete. Start i3 with 'startx' or login via display manager."
