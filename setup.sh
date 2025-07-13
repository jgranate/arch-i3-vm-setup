#!/bin/bash
set -e

echo "==> Syncing time and updating system..."
sudo timedatectl set-ntp true
sudo pacman -Syu --noconfirm

echo "==> Installing base packages from packages.txt..."
# Make sure yay is not in the package list
grep -v '^yay$' packages.txt | xargs sudo pacman -S --needed --noconfirm

# === Install yay if not present ===
if ! command -v yay &>/dev/null; then
  echo "==> Installing yay from AUR..."
  sudo pacman -S --needed --noconfirm git base-devel

  tmpdir=$(mktemp -d)
  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  cd "$tmpdir/yay"
  makepkg -si --noconfirm
  cd -
  rm -rf "$tmpdir"
fi

echo "==> Copying dotfiles..."
mkdir -p ~/.config
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
git clone https://github.com/lr-tech/rofi-themes-collection.git /tmp/rofi-themes-collection
mkdir -p ~/.local/share/rofi/themes
cp /tmp/rofi-themes-collection/themes/*.rasi ~/.local/share/rofi/themes/

echo "==> Applying default Rofi theme..."
mkdir -p ~/.config/rofi
echo '@import "~/.local/share/rofi/themes/nord.rasi"' > ~/.config/rofi/config.rasi
rm -rf /tmp/rofi-themes-collection

echo "==> Enabling VMware tools..."
sudo systemctl enable vmtoolsd.service
echo "==> Enabling LightDM display manager..."
sudo systemctl enable lightdm.service

echo "==> Applying WirePlumber stutter fix..."
mkdir -p ~/.config/wireplumber/wireplumber.conf.d
cat > ~/.config/wireplumber/wireplumber.conf.d/50-alsa-config.conf <<EOF
monitor.alsa.rules = [
  {
    matches = [
      {
        node.name = "~alsa_output.*"
      }
    ]
    actions = {
      update-props = {
        api.alsa.period-size = 1024
        api.alsa.headroom = 8192
      }
    }
  }
]
EOF

echo "==> Restarting PipeWire services..."
systemctl --user restart wireplumber pipewire pipewire-pulse || true


echo "==> Setup complete. Run 'startx' to enter i3."
