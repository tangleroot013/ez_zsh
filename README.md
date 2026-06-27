# ez_zsh
Complete setup for Chrombook crostini terminal coding
# zsh-poweruser

Production-grade Zsh environment for Chromebook Linux (Crostini/Debian).
Single `install.sh` gets you from a bare container to a full power-user shell.

## What's included

| File | Purpose |
|---|---|
| `.zshrc` | Main shell config — annotated, ordered correctly |
| `install.sh` | Idempotent bootstrap: apt, plugins, starship, zoxide |
| `update.sh` | Pull latest for all plugins and this repo |
| `themes/starship.toml` | Starship prompt with git, language, time segments |
| `functions/extras.zsh` | Optional extended functions (git, docker, python, network) |
| `completions/` | Drop-in completion files for tools not in apt |
| `docs/KEYBINDINGS.md` | Full keybinding reference |
| `docs/PLUGINS.md` | Plugin loading order contract and troubleshooting |

## Quick start

```bash
# Enable Linux in ChromeOS Settings → Linux (Beta), then:
git clone https://github.com/<you>/zsh-poweruser ~/.zsh/dotfiles
cd ~/.zsh/dotfiles
chmod +x install.sh update.sh
./install.sh
# Log out and back in, or: exec zsh
```

## Plugin loading order

Order is not arbitrary — each step has a hard dependency on the previous one:

```
fpath mutations
    └── compinit          (one call, after all fpath additions)
        └── fast-syntax-highlighting   (before autosuggestions)
            └── zsh-autosuggestions
                └── ZVM_* variables   (read at plugin init time)
                    └── zsh-vi-mode
                        └── zvm_after_init hook
                            └── zsh-history-substring-search + bindings
```

Bindings for history-substring-search live inside `zvm_after_init` because
`zsh-vi-mode` resets all keymaps after it loads. Any `bindkey` set before that
hook fires gets silently clobbered.

## Keybindings (insert mode)

| Keys | Action |
|---|---|
| `jk` | Exit insert mode (vi-mode) |
| `↑` / `Ctrl-P` | History substring search up |
| `↓` / `Ctrl-N` | History substring search down |
| `Ctrl-R` | Incremental history search |
| `Ctrl-A` / `Ctrl-E` | Line start / end |
| `Ctrl-K` | Kill to end of line |
| `Ctrl-U` | Kill to start of line |
| `Ctrl-W` | Delete previous word |
| `Tab` | Menu completion |
| `h/j/k/l` | Navigate completion menu (vi-style) |

In `vicmd` (normal) mode: `j`/`k` walk history-substring-search.

## Updating

```bash
cd ~/.zsh/dotfiles
./update.sh
source ~/.zshrc
```

## Optional extras

Load the extended function set by adding to `.zshrc`:

```zsh
source "$HOME/.zsh/dotfiles/functions/extras.zsh"
```

Provides: `git_fzf_branch`, `fe` (fzf+nvim), `fkill`, `mkvenv`, `activate`,
`bak`, `biggest`, `docker_clean`, `docker_exec`, `myip`, `timecurl`.

## Tool dependencies

Required (installed by `install.sh`):

```
zsh  git  neovim  ripgrep  fd-find  fzf  direnv
unzip  p7zip-full  zsh-syntax-highlighting  zsh-autosuggestions
```

Installed by script (not in apt):

```
zoxide    — smart cd with frecency
starship  — cross-shell prompt
```

Git-cloned plugins:

```
zsh-completions
zsh-history-substring-search
fast-syntax-highlighting
zsh-vi-mode
```
