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
create_symlink "$DOTFILES_LINK/configs/herdr" "$CONFIG_DIR/herdr"
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
# A fresh clone creates the submodule MOUNTPOINT directories as empty dirs, so a
# plain [ -d ] check would wrongly report the plugins as present and skip the
# init entirely — the plugins then never land on the new machine. Probe for a
# real file inside the checkout instead, and make the init unconditional-safe.
if [ ! -f "$DOTFILES_DIR/configs/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh" ] ||
   [ ! -f "$DOTFILES_DIR/configs/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    echo "  Initializing git submodules..."
    git -C "$DOTFILES_DIR" submodule update --init --recursive
else
    echo "  OK: zsh plugins present"
fi

echo ""
echo "=== Step 6: herdr agent integrations ==="
# The herdr -> opencode plugin (configs/opencode/plugins/herdr-agent-state.js) is
# DELIBERATELY gitignored (herdr rewrites the file on every integration update),
# so a fresh clone symlinks ~/.config/opencode into this repo with an EMPTY
# plugins/ directory — the plugin would silently never load and herdr would lose
# agent-state reporting (working/blocked/idle) for opencode. Reinstalling the
# integration recreates it; the command is idempotent and a no-op when current.
# The claude hook lives outside dotfiles (~/.claude/hooks) but is equally absent
# on a fresh machine, so it is reinstalled here too.
if command -v herdr >/dev/null 2>&1; then
    for target in opencode claude; do
        echo "  herdr integration install $target"
        herdr integration install "$target" || echo "  WARNING: herdr integration install $target failed; run it manually."
    done

    # Local wt plugin (worktree slot menu): the SOURCE is tracked in git, but
    # herdr's registry (plugins.json) and per-plugin config dir are runtime state
    # (gitignored), so a fresh clone has the files without the REGISTRATION —
    # prefix+e would do nothing until the plugin is linked again. Idempotent.
    echo "  herdr plugin link configs/herdr/plugins/wt"
    herdr plugin link "$DOTFILES_DIR/configs/herdr/plugins/wt" ||
        echo "  WARNING: herdr plugin link failed; run it manually."

    # The menu auto-discovers the repo from the workspace cwd, but pinning it
    # keeps prefix+e working from non-boemar workspaces too. Seed once; the
    # file is hers to keep (gitignored runtime config).
    wt_cfg_repo="$HOME/.config/herdr/plugins/config/boemar.wt/repo"
    if [ ! -f "$wt_cfg_repo" ] && [ -d "$HOME/Documents/boemar-hr" ]; then
        mkdir -p "$(dirname "$wt_cfg_repo")"
        echo "$HOME/Documents/boemar-hr" > "$wt_cfg_repo"
        echo "  Seeded wt plugin repo pin: $wt_cfg_repo"
    fi

    # The wt menu pane runs "bun src/menu.ts" — without bun the popup dies
    # instantly. Not auto-installed here (brew bun would duplicate the official
    # ~/.bun install), just surfaced.
    command -v bun >/dev/null 2>&1 ||
        echo "  WARNING: bun not found — the wt menu needs it (https://bun.sh)."
else
    echo "  WARNING: herdr not found — skipping integration install."
    echo "  After installing herdr (brew install herdr), run:"
    echo "    herdr integration install opencode"
    echo "    herdr integration install claude"
    echo "    herdr plugin link ~/Documents/dotfiles/configs/herdr/plugins/wt"
fi

echo ""
echo "=== Step 7: Verify the shell end-state ==="
# Fresh interactive zsh reads the JUST-SYMLINKED ~/.zshrc, so this proves the
# real boot path: both plugin submodules source cleanly. Non-fatal by design —
# a WARNING tells the user what to fix instead of aborting the install.
plugin_report="$(zsh -ic '
[[ -n $functions[_zsh_autosuggest_start] ]] && echo "autosuggestions: OK" || echo "autosuggestions: MISSING"
[[ -n $functions[_zsh_highlight] ]] && echo "syntax-highlighting: OK" || echo "syntax-highlighting: MISSING"
' 2>/dev/null | grep -E 'OK|MISSING' || true)"
echo "$plugin_report" | sed 's/^/  /'
# Both lines must be present AND say OK — an empty report (zsh itself failed to
# boot the config) must not read as success.
if echo "$plugin_report" | grep -qx "autosuggestions: OK" &&
   echo "$plugin_report" | grep -qx "syntax-highlighting: OK"; then
    echo "  OK: zsh plugins load in a fresh interactive shell"
else
    echo "  WARNING: a zsh plugin did not load. Check that Step 5 initialized the"
    echo "  submodules and that ~/.zshrc sources them (tail of configs/zsh/.zshrc)."
fi

echo ""
echo "=== Done! ==="
echo "Restart your terminal or run: source ~/.zshrc"
