# ==============================================================================
# .zshrc — Chromebook Crostini Power-User Shell
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Environment
# ------------------------------------------------------------------------------
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LESS="-R --use-color"
export LANG="en_US.UTF-8"
export TERM="xterm-256color"
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# ------------------------------------------------------------------------------
# 2. History
# ------------------------------------------------------------------------------
HISTSIZE=100000
SAVEHIST=100000
HISTFILE="$HOME/.zsh_history"

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE

# ------------------------------------------------------------------------------
# 3. ZVM Variable Setup (Must be declared BEFORE loading zsh-vi-mode)
# ------------------------------------------------------------------------------
ZVM_VI_ESCAPE_BINDKEY="jk"

# ------------------------------------------------------------------------------
# 4. Load Plugins (Ordered Core Framework Contract)
# ------------------------------------------------------------------------------
# 1st: Load Vi Mode framework so its ZLE hooks initialize first
source "$HOME/.zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh" 2>/dev/null

# 2nd: Load Syntax Highlighting to avoid 'unhandled ZLE widget accept' warnings
source "$HOME/.zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" 2>/dev/null

# 3rd: Load Complements and suggestions
source "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" 2>/dev/null
source "$HOME/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh" 2>/dev/null

# ------------------------------------------------------------------------------
# 5. Post-Initialization Plugin Hooks
# ------------------------------------------------------------------------------
function zvm_after_init() {
  # History substring search configuration bindings
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey -M vicmd 'k' history-substring-search-up
  bindkey -M vicmd 'j' history-substring-search-down
}

# ------------------------------------------------------------------------------
# 6. Binary Initializations
# ------------------------------------------------------------------------------
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# ------------------------------------------------------------------------------
# 7. Core Options & Safe Completions
# ------------------------------------------------------------------------------
setopt NO_BG_NICE
setopt NO_HUP
setopt NO_LIST_BEEP
setopt LOCAL_OPTIONS
setopt LOCAL_TRAPS

autoload -Uz compinit
[[ -d "$XDG_CACHE_HOME/zsh" ]] || mkdir -p "$XDG_CACHE_HOME/zsh/compcache"
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

# ------------------------------------------------------------------------------
# 8. Key bindings
# ------------------------------------------------------------------------------
bindkey '^A'    beginning-of-line
bindkey '^E'    end-of-line
bindkey '^K'    kill-line
bindkey '^U'    backward-kill-line
bindkey '^W'    backward-kill-word
bindkey '^[[3~' delete-char
bindkey '^H'    backward-delete-char

# Optional extras
[[ -f "$HOME/.zsh/dotfiles/functions/extras.zsh" ]] && source "$HOME/.zsh/dotfiles/functions/extras.zsh"
