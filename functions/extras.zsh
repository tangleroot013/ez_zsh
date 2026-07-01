
# ── Interactive TUI Process Killer (FZF Power-up) ──────────────────────────
fkill() {
  local pid
  if [ "$UID" -ne 0 ]; then
    pid=$(ps -f -u $USER | fzf --header="Select process to KILL (Ctrl+C to abort)" --reverse --height=40% --border=rounded | awk "{print \$2}")
  else
    pid=$(ps -ef | fzf --header="Select process to KILL (Ctrl+C to abort)" --reverse --height=40% --border=rounded | awk "{print \$2}")
  fi
  
  if [ "x$pid" != "x" ]; then
    echo "$pid" | xargs kill -9
    printf "\r\033[K\033[1;32m✔\033[0m Terminated process %s\n" "$pid"
  fi
}

# ── Clean Streamlined Git Status Alias ────────────────────────────────────────
alias g="git status -sb"


# ── Clean TUI Utility Loggers ──────────────────────────────────────────────────
tui_status() {
  printf "\r\033[K\033[1;34m⬢\033[0m Checking: \033[36m%s\033[0m..." "$*"
}

tui_ok() {
  printf "\r\033[K\033[1;32m✔\033[0m %s \033[32m(done)\033[0m\n" "$*"
}

tui_run_silent() {
  local task_desc="$1"; shift
  tui_status "$task_desc"
  local tmp_log=$(mktemp)
  if "$@" > "$tmp_log" 2>&1; then
    tui_ok "$task_desc"; rm -f "$tmp_log"; return 0
  else
    printf "\r\033[K\033[1;31m✘\033[0m \033[1;31mFailed: %s\033[0m\n" "$task_desc"
    rm -f "$tmp_log"; return 1
  fi
}
