#!/bin/bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Dotfiles Installer ==="
echo "Dotfiles directory: $DOTFILES_DIR"
echo ""

# Install official packages
echo ">>> Installing official packages..."
if [ -f "$DOTFILES_DIR/packages/official.txt" ]; then
    sudo pacman -S --needed --noconfirm - < "$DOTFILES_DIR/packages/official.txt"
else
    echo "Warning: official.txt not found"
fi

# Install AUR packages with yay
echo ""
echo ">>> Installing AUR packages..."
if ! command -v yay &> /dev/null; then
    echo "yay not found, installing..."
    sudo pacman -S --needed git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si
    cd -
fi

if [ -f "$DOTFILES_DIR/packages/aur.txt" ]; then
    yay -S --needed --noconfirm - < "$DOTFILES_DIR/packages/aur.txt"
else
    echo "Warning: aur.txt not found"
fi

# Create config symlinks
echo ""
echo ">>> Creating config symlinks..."
mkdir -p ~/.config

for config in "$DOTFILES_DIR"/config/*; do
    name=$(basename "$config")
    target="$HOME/.config/$name"

    if [ -L "$target" ]; then
        rm "$target"
    fi

    ln -s "$config" "$target"
    echo "Linked: ~/.config/$name"
done

# Create .local/bin symlink for pls
echo ""
echo ">>> Setting up .local/bin/pls..."
mkdir -p ~/.local/bin

if [ -f "$DOTFILES_DIR/local/bin/pls" ]; then
    target="$HOME/.local/bin/pls"

    if [ -L "$target" ]; then
        rm "$target"
    fi

    ln -s "$DOTFILES_DIR/local/bin/pls" "$target"
    echo "Linked: ~/.local/bin/pls"
fi

echo ""
echo "=== Installation complete! ==="

rm $HOME/.bashrc

ln -s $DOTFILES_DIR/bashrc $HOME/.bashrc
