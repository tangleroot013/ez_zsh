#!/usr/bin/env bash
# ==============================================================================
# install.sh — Chromebook Crostini Zsh power-user bootstrap
# Idempotent: safe to run more than once.
# ==============================================================================
set -euo pipefail

PLUGIN_DIR="$HOME/.zsh/plugins"
DOTFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Color helpers ─────────────────────────────────────────────────────────────
green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }
red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
info()   { printf '\033[0;36m[*]\033[0m %s\n'  "$*"; }
ok()     { printf '\033[0;32m[✔]\033[0m %s\n'  "$*"; }
warn()   { printf '\033[0;33m[!]\033[0m %s\n'  "$*"; }
die()    { printf '\033[0;31m[✘]\033[0m %s\n'  "$*" >&2; exit 1; }

# ── Dependency check ───────────────────────────────────────────────────────────
need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required tool: $1 is not installed."
}

need_cmd git
need_cmd curl
need_cmd apt-get

# ── APT packages ───────────────────────────────────────────────────────────────
readonly -a APT_PACKAGES=(
  zsh
  git
  neovim
  ripgrep
  fd-find
  fzf
  direnv
  unzip
  p7zip-full
  zsh-syntax-highlighting
  zsh-autosuggestions
)

info "Updating apt packages cache and installing dependencies..."
sudo apt-get update -qq
sudo apt-get install -y "${APT_PACKAGES[@]}"
ok "System packages installed successfully."

# Crostini/Debian package 'fd-find' ships as 'fdfind'. Symlink to 'fd'.
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
  ok "Linked fdfind → /usr/local/bin/fd"
fi

# ── Zoxide Setup ───────────────────────────────────────────────────────────────
if ! command -v zoxide >/dev/null 2>&1; then
  info "Installing zoxide (smart cd utility)..."
  curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
  ok "zoxide installed."
else
  ok "zoxide already installed."
fi

# ── Starship Prompt Setup ──────────────────────────────────────────────────────
if ! command -v starship >/dev/null 2>&1; then
  info "Installing starship prompt..."
  curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
  ok "starship installed."
else
  ok "starship prompt already installed."
fi

# ── fzf Shell Integration ──────────────────────────────────────────────────────
if [[ ! -f "$HOME/.fzf.zsh" ]]; then
  if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
    info "Configuring fzf shell integration..."
    mkdir -p "$HOME/.fzf"
    cp /usr/share/doc/fzf/examples/key-bindings.zsh "$HOME/.fzf/key-bindings.zsh"
    cp /usr/share/doc/fzf/examples/completion.zsh "$HOME/.fzf/completion.zsh" 2>/dev/null || true
    cat > "$HOME/.fzf.zsh" <<'INNER_EOF'
# fzf shell integration (managed by install.sh)
[[ -f ~/.fzf/key-bindings.zsh ]] && source ~/.fzf/key-bindings.zsh
[[ -f ~/.fzf/completion.zsh   ]] && source ~/.fzf/completion.zsh
INNER_EOF
    ok "fzf keybindings compiled to ~/.fzf.zsh"
  else
    warn "Debian fzf system templates missing; skipped auto-binding."
  fi
else
  ok "fzf integration files validated."
fi

# ── Git Plugins Setup ──────────────────────────────────────────────────────────
# Declared with explicit type to prevent namespace collisions
declare -A PLUGINS=(
  [zsh-completions]="https://github.com/zsh-users/zsh-completions"
  [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions"
  [zsh-history-substring-search]="https://github.com/zsh-users/zsh-history-substring-search"
  [fast-syntax-highlighting]="https://github.com/zdharma-continuum/fast-syntax-highlighting"
  [zsh-vi-mode]="https://github.com/jeffreytse/zsh-vi-mode"
)

mkdir -p "$PLUGIN_DIR"

for name in "${!PLUGINS[@]}"; do
  target="$PLUGIN_DIR/$name"
  if [[ -d "$target" ]]; then
    info "Plugin exists. Pulling updates: $name"
    git -C "$target" pull --ff-only --quiet
    ok "$name updated."
  else
    info "Cloning plugin: $name"
    git clone --depth=1 "${PLUGINS[$name]}" "$target" --quiet
    ok "$name initialized."
  fi
done

# ── Starship Config Migration ──────────────────────────────────────────────────
STARSHIP_CFG="$HOME/.config/starship.toml"
if [[ ! -f "$STARSHIP_CFG" ]]; then
  mkdir -p "$(dirname "$STARSHIP_CFG")"
  if [[ -f "$DOTFILE_DIR/themes/starship.toml" ]]; then
    cp "$DOTFILE_DIR/themes/starship.toml" "$STARSHIP_CFG"
  else
    cat > "$STARSHIP_CFG" <<'INNER_EOF'
# starship.toml — Crostini configuration fallback
"$schema" = 'https://starship.rs/config-schema.json'
add_newline = false

[character]
success_symbol = "[❯](green)"
error_symbol   = "[❯](red)"
vimcmd_symbol  = "[❮](yellow)"

[directory]
truncation_length = 4
truncate_to_repo  = true

[git_branch]
symbol = " "
INNER_EOF
  fi
  ok "starship configuration integrated."
else
  ok "starship configuration already present."
fi

# ── Symlink and Shell Deployment ───────────────────────────────────────────────
ZSHRC_SRC="$DOTFILE_DIR/.zshrc"
ZSHRC_DST="$HOME/.zshrc"

if [[ -f "$ZSHRC_DST" && ! -L "$ZSHRC_DST" ]]; then
  backup="$ZSHRC_DST.bak.$(date +%Y%m%d_%H%M%S)"
  warn "Backing up pre-existing configuration: ~/.zshrc → $backup"
  cp "$ZSHRC_DST" "$backup"
fi

ln -sf "$ZSHRC_SRC" "$ZSHRC_DST"
ok "~/.zshrc deployment complete via local symbolic link."

# ── Update Shell Default ───────────────────────────────────────────────────────
ZSH_BIN=$(command -v zsh)
if [[ "${SHELL:-}" != "$ZSH_BIN" ]]; then
  info "Configuring Default Shell environment inside Crostini..."
  sudo chsh -s "$ZSH_BIN" "$USER"
  ok "Default shell updated to Zsh. Changes take effect on container restart."
else
  ok "Zsh is already registered as default."
fi

# Create Zsh internal directory dependencies
mkdir -p "$HOME/.cache/zsh/compcache"

printf '\n'
green ""
green "  Ez_zsh Install Engine Execution: Finished."
green "  Please reload your container or type: exec zsh"
green ""
