#!/usr/bin/env bash
# update.sh — pull latest changes for all plugins + this repo
set -euo pipefail

PLUGIN_DIR="$HOME/.zsh/plugins"
DOTFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ok()   { printf '\033[0;32m[✔]\033[0m %s\n' "$*"; }
info() { printf '\033[0;36m[*]\033[0m %s\n' "$*"; }

# Update this repo
info "Updating dotfiles repo…"
git -C "$DOTFILE_DIR" pull --ff-only
ok "Dotfiles up to date."

# Update each plugin
for plugin_dir in "$PLUGIN_DIR"/*/; do
  name=$(basename "$plugin_dir")
  info "Updating $name…"
  git -C "$plugin_dir" pull --ff-only --quiet && ok "$name updated."
done

# Update zoxide if installed via the official script
if command -v zoxide >/dev/null 2>&1; then
  info "Updating zoxide…"
  curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
  ok "zoxide updated."
fi

# Update starship if installed
if command -v starship >/dev/null 2>&1; then
  info "Updating starship…"
  curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
  ok "starship updated."
fi

printf '\n'
printf '\033[0;32mAll plugins updated. Run: source ~/.zshrc\033[0m\n'
