#!/bin/bash

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_LINK="$HOME/.dotfiles"
CONFIG_DIR="$HOME/.config"

backup() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
        echo "  Backing up $target -> $backup"
        mv "$target" "$backup"
    fi
}

create_symlink() {
    local source="$1"
    local target="$2"

    if [ -L "$target" ]; then
        local current
        current="$(readlink "$target")"
        if [ "$current" = "$source" ]; then
            echo "  OK: $target"
            return
        fi
        echo "  Updating symlink: $target"
        rm "$target"
    else
        backup "$target"
        echo "  Creating symlink: $target -> $source"
    fi

    ln -s "$source" "$target"
}

echo "=== Step 1: Homebrew packages ==="
if command -v brew >/dev/null 2>&1; then
    if [ -f "$DOTFILES_DIR/Brewfile" ]; then
        echo "  Running brew bundle..."
        brew bundle --file="$DOTFILES_DIR/Brewfile" --no-upgrade
    fi
else
    echo "  Homebrew not found. Install from https://brew.sh"
    echo "  Then re-run this script."
    exit 1
fi

echo ""
echo "=== Step 2: Setting up .dotfiles link ==="
mkdir -p "$CONFIG_DIR"

if [ -L "$DOTFILES_LINK" ]; then
    current="$(readlink "$DOTFILES_LINK")"
    if [ "$current" = "$DOTFILES_DIR" ]; then
        echo "  OK: $DOTFILES_LINK"
    else
        echo "  Updating $DOTFILES_LINK -> $DOTFILES_DIR"
        rm "$DOTFILES_LINK"
        ln -s "$DOTFILES_DIR" "$DOTFILES_LINK"
    fi
elif [ -d "$DOTFILES_LINK" ]; then
    echo "  WARNING: $DOTFILES_LINK is a real directory, not a symlink."
    echo "  Please migrate manually."
else
    ln -s "$DOTFILES_DIR" "$DOTFILES_LINK"
    echo "  Created: $DOTFILES_LINK -> $DOTFILES_DIR"
fi

echo ""
echo "=== Step 3: XDG Config symlinks (~/.config/*) ==="

create_symlink "$DOTFILES_LINK/configs/kitty" "$CONFIG_DIR/kitty"
create_symlink "$DOTFILES_LINK/configs/nvim" "$CONFIG_DIR/nvim"
create_symlink "$DOTFILES_LINK/configs/tmux" "$CONFIG_DIR/tmux"
create_symlink "$DOTFILES_LINK/configs/git" "$CONFIG_DIR/git"
create_symlink "$DOTFILES_LINK/configs/gh" "$CONFIG_DIR/gh"
create_symlink "$DOTFILES_LINK/configs/opencode" "$CONFIG_DIR/opencode"

echo ""
echo "=== Step 4: Home directory symlinks ==="

create_symlink "$DOTFILES_LINK/configs/zsh/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_LINK/configs/zsh/.zprofile" "$HOME/.zprofile"
create_symlink "$DOTFILES_LINK/configs/git/.gitconfig" "$HOME/.gitconfig"

echo ""
echo "=== Step 5: Git submodules (zsh plugins) ==="
if [ ! -d "$DOTFILES_DIR/configs/zsh/plugins/zsh-autosuggestions" ]; then
    echo "  Initializing git submodules..."
    git -C "$DOTFILES_DIR" submodule update --init --recursive
else
    echo "  OK: zsh plugins present"
fi

echo ""
echo "=== Done! ==="
echo "Restart your terminal or run: source ~/.zshrc"
