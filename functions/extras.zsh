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

# ── Resilient Interactive TUI Directory Jump Engine ──────────────────────────
zi() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: zi [QUERY]"
    return 0
  fi

  if ! command -v zoxide >/dev/null 2>&1 || ! command -v fzf >/dev/null 2>&1; then
    printf "\033[1;31m✘ Error:\033[0m Missing dependencies.\n" >&2
    return 1
  fi

  # Safely check if zoxide database contains records before running fzf
  local z_list
  z_list=$(zoxide query -l)
  if [[ -z "$z_list" ]]; then
    printf "\033[1;33m⚠ Zoxide history database is currently empty.\033[0m\n"
    printf "Walk into a few folders using regular 'cd' commands first to build the index!\n"
    return 0
  fi

  local target_dir
  target_dir=$(echo "$z_list" | fzf \
    --height="40%" --reverse --border="rounded" \
    --prompt="🗂️ Jump to Directory ❯ " \
    --query="${*:-}")

  if [[ -n "$target_dir" ]]; then
    cd "$target_dir" && tui_ok "Context shifted to: $(pwd)"
  fi
}

# ── Interactive TUI Git Commit Browser ────────────────────────────────────────
gh() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf "\033[1;31m✘ Error:\033[0m Not inside a git repository matrix.\n" >&2
    return 1
  fi

  local commit
  commit=$(git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" | \
    fzf --ansi \
        --no-sort \
        --reverse \
        --tiebreak=index \
        --height=60% \
        --border=rounded \
        --prompt="🕒 Commit History Matrix ❯ " \
        --header="Use arrows to browse / Press Enter to yank hash" \
        --preview="echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I % git show --color=always %" \
        --preview-window=right:60%:wrap)

  if [[ -n "$commit" ]]; then
    local hash
    hash=$(echo "$commit" | grep -o '[a-f0-9]\{7\}' | head -1)
    printf "\033[1;32m✔ Selected Commit Hash:\033[0m %s\n" "$hash"
    # Automatically copies the hash to your clipboard if xclip or pbcopy exists
    command -v xclip >/dev/null 2>&1 && echo -n "$hash" | xclip -selection clipboard
  fi
}

# ── Interactive Smart File Opener ─────────────────────────────────────────────
fo() {
  local target_file
  # Filters out standard junk folders like node_modules and .git automatically
  target_file=$(find . -maxdepth 4 -not -path '*/.*' -not -path './node_modules*' -not -path './__pycache__*' -type f 2>/dev/null | fzf \
    --height="40%" \
    --reverse \
    --border="rounded" \
    --prompt="🔍 Select File to Open ❯ " \
    --header="Type to filter / Enter opens in Neovim")

  if [[ -n "$target_file" ]]; then
    nvim "$target_file"
  fi
}

# ── High-Performance Live System Monitor ─────────────────────────────────────
sys() {
  if command -v btop >/dev/null 2>&1; then
    btop
  elif command -v htop >/dev/null 2>&1; then
    htop
  else
    top
  fi
}

# ── Interactive Inside-File Content Search Engine ─────────────────────────────
frg() {
  if ! command -v rg >/dev/null 2>&1; then
    printf "\033[1;31m✘ Error:\033[0m ripgrep ('rg') dependency not found.\n" >&2
    return 1
  fi

  local selection
  selection=$(rg --line-number --column --no-heading --color=always --smart-case "${*:-""}" | fzf \
    --ansi \
    --color "hl:-1:underline,hl+:-1:underline:reverse" \
    --delimiter : \
    --reverse \
    --height=60% \
    --border=rounded \
    --prompt="✨ Find Code Matches ❯ " \
    --preview="bat --color=always --style=numbers {1} --highlight-line {2} 2>/dev/null || head -n +100 {1}" \
    --preview-window="right:60%:wrap")

  if [[ -n "$selection" ]]; then
    local file_path line_num
    file_path=$(echo "$selection" | awk -F: '{print $1}')
    line_num=$(echo "$selection" | awk -F: '{print $2}')
    # Opens Neovim directly to the exact line number matching your search
    nvim "+$line_num" "$file_path"
  fi
}

# ── Chromebook Environment High-Performance Housekeeping ──────────────────────
cleanup() {
  if command -v tui_status >/dev/null 2>&1; then
    tui_status "Initiating deep development disk cleanup"
  else
    echo "🧹 Purging environment cache matrices..."
  fi

  # 1. Clean out generic system log caches and package leftovers
  sudo apt-get autoremove -y >/dev/null 2>&1
  sudo apt-get clean >/dev/null 2>&1

  # 2. Safely purge recursive python compiler caches (__pycache__)
  find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null

  # 3. Clean Docker system data safely if docker is running
  if command -v docker >/dev/null 2>&1; then
    docker system prune -f --volumes >/dev/null 2>&1
  fi

  if command -v tui_ok >/dev/null 2>&1; then
    tui_ok "Storage optimized. Chromebook partition stabilized."
  else
    printf "\033[1;32m✔\033[0m Storage optimization complete!\n"
  fi
}

# ── Architectural Git Repository Lineage Engine ──────────────────────────────
alias gtree="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"

# ── Interactive TUI Branch Switcher & Preview Matrix ──────────────────────────
gb() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf "\033[1;31m✘ Error:\033[0m Not inside a git repository.\n" >&2
    return 1
  fi

  local target_branch
  target_branch=$(git branch --all --color=always | grep -v 'HEAD ->' | fzf \
    --ansi \
    --reverse \
    --height=50% \
    --border=rounded \
    --prompt="🌿 Select Target Branch ❯ " \
    --header="Enter to Checkout / Ctrl+C to Escape" \
    --preview="git log --color=always -n 5 --oneline \$(echo {} | sed 's/remotes\/origin\///' | tr -d '* ') 2>/dev/null")

  if [[ -n "$target_branch" ]]; then
    # Clean up string markers from the selection output
    local clean_branch
    clean_branch=$(echo "$target_branch" | tr -d '* ' | sed 's/remotes\/origin\///')
    git checkout "$clean_branch"
  fi
}

# ── Safe Ephemeral Code Scratchpad Tool ───────────────────────────────────────
scratch() {
  local scratch_dir="$HOME/.local/share/scratchpads"
  mkdir -p "$scratch_dir"

  local ext="${1:-txt}"
  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  local filepath="$scratch_dir/scratch_$timestamp.$ext"

  printf "\033[34mℹ Creating scratchpad:\033[0m %s\n" "$filepath"
  nvim "$filepath"
}

# ── Active Network Port Diagnostic Monitor ────────────────────────────────────
ports() {
  if command -v ss >/dev/null 2>&1; then
    printf "\033[1;34m⚡ Active Network Listeners Matrix:\033[0m\n"
    ss -tulnp | grep -v "Netid" | awk '{print $1, $5, $7}' | column -t
  else
    printf "\033[1;34m⚡ Active Socket Allocations:\033[0m\n"
    netstat -tuln | column -t
  fi
}

# ── Rapid Automated Code Tracking Matrix Snapshot ─────────────────────────────
snap() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf "\033[1;31m✘ Error:\033[0m Workspace context is unversioned.\n" >&2
    return 1
  fi

  local current_branch
  current_branch=$(git branch --show-current)
  local msg="snapshot: backup tracking update via TUI ($(date '+%Y-%m-%d %H:%M'))"

  if command -v tui_status >/dev/null 2>&1; then
    tui_status "Locking down working index state"
  fi

  git add -A
  if git commit -m "$msg" >/dev/null 2>&1; then
    if command -v tui_ok >/dev/null 2>&1; then
      tui_ok "Commit matrix solidified: $msg"
      tui_status "Syncing upstream to origin/$current_branch"
    fi
    
    if git push origin "$current_branch" >/dev/null 2>&1; then
      tui_ok "Remote data safely replicated."
    else
      printf "\033[1;33m⚠ Warning:\033[0m Pushing failed. Network down or upstream desynced.\n"
    fi
  else
    printf "\033[1;32m✔\033[0m Working layout matches tree state. No snapshot modifications found.\n"
  fi
}

# ── Elite Global Directory Shortcut Bookmarks ─────────────────────────────────
dopts() {
  local choice
  choice=$(printf "%s\n" \
    "📁 Sandbox Project  ➔ ~/projects/sandbox" \
    "⚙️ Zsh Dotfiles     ➔ ~/.zsh/dotfiles" \
    "🛠️ Neovim Config   ➔ ~/.config/nvim" | fzf \
      --height=40% \
      --reverse \
      --border=rounded \
      --prompt="🗺️ Select Hotkey Jump Point ❯ ")

  case "$choice" in
    *"Sandbox Project"*) cd ~/projects/sandbox && tui_ok "Shifted to Sandbox" ;;
    *"Zsh Dotfiles"*)    cd ~/.zsh/dotfiles    && tui_ok "Shifted to Dotfiles" ;;
    *"Neovim Config"*)   cd ~/.config/nvim     && tui_ok "Shifted to Neovim" ;;
  esac
}
alias j=dopts

# ── Polygothic Workspace Inline Engine Runner ──────────────────────────────────
run() {
  local file="$1"
  if [[ -z "$file" ]]; then
    printf "\033[1;31m✘ Error:\033[0m Provide a target file execution vector.\n" >&2
    return 1
  fi
  if [[ ! -f "$file" ]]; then
    printf "\033[1;31m✘ Error:\033[0m File '%s' not found.\n" "$file" >&2
    return 1
  fi

  case "${file##*.}" in
    py)  python3 "$file" ;;
    sh)  bash "$file"    ;;
    js)  node "$file"    ;;
    *)   printf "\033[1;33m⚠ Runtime mapping missing for file extension.\033[0m\n" ;;
  esac
}

# ── Instant Contextual TUI Console Cheat-Sheet Lens ───────────────────────────
cht() {
  local query
  printf "\033[1;34m🔍 Enter topic (e.g., python/list, tar, chown): \033[0m"
  read -r query

  if [[ -n "$query" ]]; then
    tui_status "Querying global community core engine..."
    curl -s "https://cht.sh/$query" | less -R
  fi
}

# ── Smart Python Virtual Environment Context Activator ────────────────────────
va() {
  local venv_dirs=(".venv" "venv" "env" "ENV")
  for dir in "${venv_dirs[@]}"; do
    if [[ -d "$dir" && -f "$dir/bin/activate" ]]; then
      tui_status "Mounting virtual environment engine found in ./${dir}"
      source "$dir/bin/activate"
      tui_ok "Virtual Environment Active: ($(basename "$(pwd)"))"
      return 0
    fi
  done

  printf "\033[1;33m⚠ No virtual environment matrix detected.\033[0m Run 'python3 -m venv .venv' first.\n"
}

# ── High-Speed Endpoint Response & Latency Inspector ──────────────────────────
check() {
  local target="${1:-localhost:8080}"
  if [[ "$target" != http* ]]; then
    target="http://$target"
  fi

  tui_status "Pinging endpoint context: $target"
  local response
  response=$(curl -s -o /dev/null -w "Code: %{http_code} | Total Time: %{time_total}s\n" "$target" 2>/dev/null)

  if [[ $? -eq 0 ]]; then
    printf "\r\033[K\033[1;32m✔\033[0m %s" "$response"
  else
    printf "\r\033[K\033[1;31m✘ Connection Refused:\033[0m URL or local port is unresponsive.\n" >&2
  fi
}

# ── Interactive Environmental Variable TUI Browser ────────────────────────────
vemp() {
  local selected
  selected=$(printenv | fzf \
    --height=50% \
    --reverse \
    --border=rounded \
    --prompt="🔑 Inspect Active System Variables ❯ " \
    --header="Type to filter keys and exported values")
    
  if [[ -n "$selected" ]]; then
    # Cleanly echo it onto the line if selected
    echo "$selected"
  fi
}

# ── Dynamic Native Terminal Digital Stream Screensaver ────────────────────────
matrix() {
  clear; echo -e "\e[32m"; lines=$(tput lines); cols=$(tput cols)
  for ((i=1; i<=cols; i++)); do c[$i]=$((RANDOM%lines)); done
  while true; do
    for ((i=1; i<=cols; i++)); do
      printf "\e[%d;%dH " ${c[$i]} $i
      c[$i]=$((c[$i]+1))
      if [ ${c[$i]} -ge $lines ] || [ $((RANDOM%10)) -eq 1 ]; then c[$i]=$((RANDOM%lines)); fi
      printf "\e[%d;%dH%s" ${c[$i]} $i $(printf "\\$(printf '%03o' $((RANDOM%93+33)))")
    done
    sleep 0.03
  done
}

# ── Dynamic Project Structural Boilerplate Architect ──────────────────────────
mkproj() {
  local name="$1"
  if [[ -z "$name" ]]; then
    printf "\033[1;31m✘ Error:\033[0m Specify a target directory name.\n" >&2
    return 1
  fi

  local ptype
  ptype=$(printf "%s\n" "🐍 Python Starter" "🌐 Web Starter (Node)" "📄 Plain Script" | fzf \
    --height=40% --reverse --border=rounded --prompt="🛠️ Select Project Type Blueprint ❯ ")

  mkdir -p "$name" && cd "$name" || return 1
  git init >/dev/null 2>&1

  case "$ptype" in
    *"Python"*)
      printf "import sys\n\ndef main():\n    print('Hello World')\n\nif __name__ == '__main__':\n    main()\n" > main.py
      printf "__pycache__/\n.venv/\nvenv/\n" > .gitignore
      ;;
    *"Web"*)
      printf '{\n  "name": "%s",\n  "version": "1.0.0",\n  "main": "index.js",\n  "scripts": {\n    "start": "node index.js"\n  }\n}\n' "$name" > package.json
      printf "console.log('Server Engine Initialized');\n" > index.js
      printf "node_modules/\n" > .gitignore
      ;;
    *)
      touch README.md main.sh && chmod +x main.sh
      ;;
  esac

  tui_ok "Blueprint deployed successfully inside ./${name}"
}

# ── High-Efficiency Live Log Stream Watchdog ──────────────────────────────────
watchdog() {
  local target_log="$1"
  if [[ -z "$target_log" || ! -f "$target_log" ]]; then
    printf "\033[1;31m✘ Error:\033[0m Provide a valid log file path to track.\n" >&2
    return 1
  fi

  printf "\033[1;34m👀 Monitoring stream changes for: %s (Ctrl+C to stop)\033[0m\n" "$target_log"
  tail -f -n 20 "$target_log" | awk '
    /ERROR|Fail|Exception/ {print "\033[1;31m" $0 "\033[0m"; next}
    /WARN|Warning/          {print "\033[1;33m" $0 "\033[0m"; next}
    /INFO|Success|OK/       {print "\033[1;32m" $0 "\033[0m"; next}
    {print}
  '
}

# ── High-Speed Document Text Metrics Processor ──────────────────────────────
wcount() {
  local file
  file=$(find . -maxdepth 3 -type f -not -path '*/.*' 2>/dev/null | fzf --height=40% --reverse --border=rounded --prompt="📊 Analytics Target ❯ ")
  
  if [[ -n "$file" ]]; then
    printf "\033[1;34m📊 Blueprint Data Matrix Analysis for: %s\033[0m\n" "$file"
    wc "$file" | awk '{printf " ├─ Lines: %s\n ├─ Words: %s\n └─ Total Bytes: %s\n", $1, $2, $3}'
  fi
}

# ── Minimal Terminal Environment Weather Forecast Lens ────────────────────────
sky() {
  tui_status "Fetching geographic atmospheric conditions..."
  curl -s -m 4 "https://wttr.in/?0q" || printf "\r\033[K\033[1;31m✘ Infrastructure Timeout\033[0m\n"
}

# ── Cryptographically Secure String & Secret Architect ────────────────────────
genpass() {
  local length="${1:-24}"
  if [[ ! "$length" =~ ^[0-9]+$ ]]; then
    printf "\033[1;31m✘ Error:\033[0m Specify a valid numeric length value.\n" >&2
    return 1
  fi

  printf "\033[1;34m🔑 Secure Secret Target Token: \033[0m"
  # Pulls from urandom, filters alphanumeric symbols, slices by requested length
  LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()_+' < /dev/urandom | head -c "$length"
  echo ""
}

# ── Architectural Execution PATH Verifier Matrix ──────────────────────────────
vpath() {
  printf "\033[1;34m🗺️ Slicing Global Execution Path Locations:\033[0m\n"
  echo "$PATH" | tr ':' '\n' | while read -r directory; do
    if [[ -d "$directory" ]]; then
      printf " \033[1;32m✔\033[0m %s\n" "$directory"
    else
      printf " \033[1;31m✘ (Broken Link Matrix):\033[0m %s\n" "$directory"
    fi
  done
}

# ── Core Alias Dictionary Search Matrix ───────────────────────────────────────
al() {
  local target_alias
  target_alias=$(alias | fzf \
    --height=50% \
    --reverse \
    --border=rounded \
    --prompt="🚀 Active Utility Aliases ❯ " \
    --header="Type to filter registered shortcut bindings")
    
  if [[ -n "$target_alias" ]]; then
    echo "$target_alias"
  fi
}

# ── Storage Allocation Matrix Analyzer ────────────────────────────────────────
dfsz() {
  printf "\033[1;34m💾 Storage Architecture Mapping Overview:\033[0m\n"
  df -h / | awk 'NR==2 {printf " ├─ Partition: %s\n ├─ Total Scale: %s\n ├─ Utilized:   %s (%s)\n └─ Available:  %s\n", $1, $2, $3, $5, $4}'
  
  if command -v du >/dev/null 2>&1; then
    printf "\n\033[1;34m📂 Workspace Directory Footprint (Top 5 heavy paths):\033[0m\n"
    du -ahd 1 2>/dev/null | sort -rh | head -n 5 | awk '{print " ├─ " $2 " ➔ " $1}'
  fi
}

# ── Dynamic System Clipboard Mirroring Engine ─────────────────────────────────
clip() {
  local target_file="${1:-~/projects/sandbox/payload.txt}"
  printf "\033[1;34m📋 Paste raw content block below (Press Ctrl+D when finished):\033[0m\n"
  
  # Captures multi-line terminal standard stream input cleanly without escaping bugs
  cat > "$target_file"
  
  if [[ -f "$target_file" ]]; then
    tui_ok "Stream synchronized successfully to: $target_file"
    printf "📊 Data Matrix Payload Scale: %s lines written.\n" "$(wc -l < "$target_file" | tr -d ' ')"
  fi
}

# ── Automated Git Branch Clean & Vacuum Engine ────────────────────────────────
gpurge() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf "\033[1;31m✘ Error:\033[0m Workspace context is unversioned.\n" >&2
    return 1
  fi

  tui_status "Pruning dead tracking indices from origin remote..."
  git fetch --prune >/dev/null 2>&1

  local default_branch
  default_branch=$(git remote show origin | awk '/HEAD branch/ {print $3}')
  default_branch="${default_branch:-main}"

  tui_status "Evaluating merged branches against $default_branch..."
  
  # Iterates through branches safely avoiding deleting your baseline tree branch
  git branch --merged | grep -v "\*" | grep -v "$default_branch" | while read -r branch; do
    local clean_branch
    clean_branch=$(echo "$branch" | tr -d ' ')
    if [[ -n "$clean_branch" ]]; then
      git branch -d "$clean_branch" && printf " ├─ \033[1;32m✔ Swept merged path:\033[0m %s\n" "$clean_branch"
    fi
  done
  
  tui_ok "Repository branch matrix optimized."
}

# ── High-Speed Interactive Process Kill Engine ────────────────────────────────
killf() {
  local pid
  pid=$(ps -ef | grep -v "UID" | fzf \
    --height=50% \
    --reverse \
    --border=rounded \
    --prompt="💀 Select Process to Terminate ❯ " \
    --header="Type to filter PID matrices / Enter executes SIGKILL")
    
  if [[ -n "$pid" ]]; then
    local clean_pid
    clean_pid=$(echo "$pid" | awk '{print $2}')
    tui_status "Sending termination vector to PID: $clean_pid"
    kill -9 "$clean_pid" && tui_ok "Process group destroyed successfully."
  fi
}

# ── Workspace Extension Architecture Tally ────────────────────────────────────
exts() {
  printf "\033[1;34m📊 Mapping Structural File Type Ratios:\033[0m\n"
  find . -type f -not -path '*/.*' -not -path './node_modules*' 2>/dev/null | \
    sed -n 's/.*\.//p' | sort | uniq -c | sort -rn | \
    awk '{printf " ├─ Extension Type: .%-5s ➔ Allocation: %s files\n", $2, $1}'
}

# ── Core Workspace Health & Telemetry Summary ──────────────────────────────────
health() {
  printf "\033[1;35m⚙️ Terminal Engine Telemetry Dashboard Matrix:\033[0m\n"
  printf " ├─ Host Time:   %s\n" "$(date '+%Y-%m-%d %H:%M:%S')"
  printf " ├─ Shell Type:  %s (%s)\n" "$ZSH_NAME" "$ZSH_VERSION"
  
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf " ├─ Git Status:  \033[1;32mVersioned\033[0m (Branch: %s)\n" "$(git branch --show-current)"
  else
    printf " ├─ Git Status:  \033[1;33mStandalone Directory\033[0m\n"
  fi
  
  printf " └─ Core Uptime: %s\n" "$(uptime -p | sed 's/up //')"
}

# ── Persistent Terminal Workspace Session Engine ──────────────────────────────
sess() {
  if ! command -v tmux >/dev/null 2>&1; then
    printf "\033[1;31m✘ Error:\033[0m Multiplexer engine ('tmux') is not installed.\n" >&2
    return 1
  fi

  local session
  session=$(tmux list-sessions -F "#S" 2>/dev/null | fzf \
    --height=40% \
    --reverse \
    --border=rounded \
    --prompt="⏳ Select Multiplexer Session ❯ " \
    --header="Enter to attach / Type a new name to create custom session Matrix")

  if [[ -z "$session" ]]; then
    return 0
  fi

  # If the selected session does not exist in active pool, spawn it out right now
  if ! tmux has-session -t "$session" 2>/dev/null; then
    tmux new-session -d -s "$session"
  fi
  tmux attach-session -t "$session"
}

# ── High-Speed Workspace Extension Migration Engine ───────────────────────────
mvtype() {
  local old_ext="$1"
  local new_ext="$2"

  if [[ -z "$old_ext" || -z "$new_ext" ]]; then
    printf "\033[1;31m✘ Error:\033[0m Map parameters cleanly: 'mvtype <old_ext> <new_ext>'\n" >&2
    return 1
  fi

  local count=0
  for file in *."$old_ext"; do
    if [[ -f "$file" ]]; then
      mv "$file" "${file%.$old_ext}.$new_ext"
      ((count++))
    fi
  done

  tui_ok "Extension transformation execution matrix complete. Modified: $count items."
}

# ── Dynamic Project Directory Architecture Mapper ─────────────────────────────
tre() {
  printf "\033[1;34m🌿 Layout Structure Matrix Mapping for: $(pwd)\033[0m\n"
  if command -v tree >/dev/null 2>&1; then
    tree -I 'node_modules|__pycache__|.git|.venv' -F --dirsfirst "$@"
  else
    # Elegant fallback sequence for uninstalled platforms
    find . -maxdepth 3 -not -path '*/.*' -not -path './node_modules*' -not -path './__pycache__*' | sed -e 's;[^/]*/;|____;g;s;____|; |;g'
  fi
}

# ── High-Speed Cryptographic Hash Telemetry Reader ───────────────────────────
md5f() {
  local target_file
  target_file=$(find . -maxdepth 3 -type f -not -path '*/.*' 2>/dev/null | fzf \
    --height=40% --reverse --border=rounded --prompt="🔒 Select Target Data Footprint ❯ ")

  if [[ -n "$target_file" ]]; then
    printf "\033[1;34m🔒 Structural Integrity Checksums for: %s\033[0m\n" "$target_file"
    if command -v sha256sum >/dev/null 2>&1; then
      printf " ├─ SHA256: %s\n" "$(sha256sum "$target_file" | awk '{print $1}')"
    fi
    if command -v md5sum >/dev/null 2>&1; then
      printf " └─ MD5:    %s\n" "$(md5sum "$target_file" | awk '{print $1}')"
    fi
  fi
}

# ── Interactive Workspace Git Diff Delta Inspector ────────────────────────────
gdiff() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf "\033[1;31m✘ Error:\033[0m Matrix context is not inside a git workspace.\n" >&2
    return 1
  fi

  local target_file
  target_file=$(git status --porcelain | awk '{print $2}' | fzf \
    --height=50% \
    --reverse \
    --border=rounded \
    --prompt="🔍 Select File to Diff ❯ " \
    --header="Use arrows to browse file diff previews" \
    --preview="git diff --color=always {}")

  if [[ -n "$target_file" ]]; then
    # Open the file up in Neovim to instantly make your tracking adjustments
    nvim "$target_file"
  fi
}

# ── Dynamic Interface & WAN Network Telemetry Monitor ─────────────────────────
myip() {
  printf "\033[1;34m🌐 Local Container Network Interfaces:\033[0m\n"
  ip -br addr show | awk '{print " ├─ " $1 " ➔ " $3}'
  
  printf "\n\033[1;34m🛰️ Global Public Network Geolocation Metrics:\033[0m\n"
  local wan_data
  wan_data=$(curl -s -m 3 "https://ipinfo.io/json" 2>/dev/null)
  
  if [[ -n "$wan_data" ]]; then
    echo "$wan_data" | sed -E 's/[{}"]//g' | awk -F: '
      /ip/       {printf " ├─ Public IP: %s\n", $2}
      /city/     {printf " ├─ City:     %s\n", $2}
      /region/   {printf " ├─ Region:   %s\n", $2}
      /org/      {printf " └─ Provider: %s\n", $2}
    '
  else
    printf " └─ \033[1;31m✘ WAN Timeout:\033[0m Offline or upstream data ping blocked.\n"
  fi
}

# ── Interactive Keyboard Command Log Query Matrix ─────────────────────────────
hs() {
  local selected_command
  selected_command=$(history -n 1 | tac | fzf \
    --height=50% \
    --reverse \
    --border=rounded \
    --prompt="📜 Search Command History Matrix ❯ " \
    --query="${*:-""}")

  if [[ -n "$selected_command" ]]; then
    # Inject chosen command into your active terminal buffer line
    print -z "$selected_command"
  fi
}

# ── Interactive Container Log Stream Inspector ───────────────────────────────
dkl() {
  if ! command -v docker >/dev/null 2>&1; then
    printf "\033[1;31m✘ Error:\033[0m Docker infrastructure engine is offline or uninstalled.\n" >&2
    return 1
  fi

  local container
  container=$(docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}" | sed 1d | fzf \
    --height=50% \
    --reverse \
    --border=rounded \
    --prompt="🐋 Select Active Container Vector ❯ " \
    --header="Enter streams live log updates / Ctrl+C to drop matrix")

  if [[ -n "$container" ]]; then
    local cid
    cid=$(echo "$container" | awk '{print $1}')
    printf "\033[1;34m⚡ Attaching stream telemetry to container process: %s\033[0m\n" "$cid"
    docker logs --tail 50 -f "$cid"
  fi
}

# ── Structured Semantic Conventional Commit Architect ─────────────────────────
gcm() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf "\033[1;31m✘ Error:\033[0m Current directory matrix is unversioned.\n" >&2
    return 1
  fi

  local choice
  choice=$(printf "%s\n" \
    "✨ feat   ➔ Core application feature advancement" \
    "🐛 fix    ➔ Code codebase bug resolution patch" \
    "📝 docs   ➔ Documentation readmes modification update" \
    "⚙️ chore  ➔ Tooling workspace configuration update" \
    "🎨 style  ➔ Structural design layout styling refresh" | fzf \
      --height=40% --reverse --border=rounded --prompt="🌿 Select Commit Prefix Vector ❯ ")

  if [[ -n "$choice" ]]; then
    local prefix
    prefix=$(echo "$choice" | awk '{print $2}')
    
    printf "\033[1;34m📝 Input commit contextual summary: \033[0m"
    read -r message
    
    if [[ -n "$message" ]]; then
      git commit -m "${prefix}: ${message}"
    fi
  fi
}

# ── Core Allocation Compute & Memory Hog Tracer ───────────────────────────────
hogs() {
  printf "\033[1;34m🔥 Top 5 Resource Allocation Hogs Matrix:\033[0m\n"
  
  printf "\n\033[1;33m💻 CPU Exhaustion Threads:\033[0m\n"
  ps -eo pid,pcpu,pmem,comm --sort=-pcpu | head -n 6 | tail -n +2 | awk '{printf " ├─ PID: %-6s | CPU: %-5s%% | MEM: %-5s%% | Command: %s\n", $1, $2, $3, $4}'
  
  printf "\n\033[1;35m💾 Memory Partition Footprints:\033[0m\n"
  ps -eo pid,pcpu,pmem,comm --sort=-pmem | head -n 6 | tail -n +2 | awk '{printf " ├─ PID: %-6s | CPU: %-5s%% | MEM: %-5s%% | Command: %s\n", $1, $2, $3, $4}'
}

# ── Automated Project Manifest Routine Blueprint Runner ───────────────────────
nr() {
  if [[ ! -f "package.json" ]]; then
    printf "\033[1;31m✘ Error:\033[0m No package.json architecture blueprint found here.\n" >&2
    return 1
  fi

  local target_script
  target_script=$(awk -F'"' '/"scripts":/,/}/ {if ($2 ~ /[^:]/ && $2 != "scripts") print $2}' package.json | tr -d ' ' | fzf \
    --height=40% --reverse --border=rounded --prompt="🚀 Select Routine Execution Vector ❯ ")

  if [[ -n "$target_script" ]]; then
    printf "\033[1;34m⚡ Booting automated script loop:\033[0m %s\n" "$target_script"
    npm run "$target_script" 2>/dev/null || yarn "$target_script"
  fi
}

# ── Interactive Ripgrep Content Search Matrix ───────────────────────────
rgf() {
  if ! command -v rg >/dev/null 2>&1; then
    printf "\033[1;31m✘ Error:\033[0m Ripgrep ('rg') engine is uninstalled.\n" >&2
    return 1
  fi

  local selection
  selection=$(rg --line-number --no-heading --color=always "${1:-.}" 2>/dev/null | fzf \
    --ansi \
    --height=60% \
    --reverse \
    --border=rounded \
    --prompt="🔍 Global String Match ❯ " \
    --header="Type to filter matching text layouts" \
    --preview="head -n 50 \$(echo {} | cut -d: -f1)")

  if [[ -n "$selection" ]]; then
    local file line
    file=$(echo "$selection" | cut -d: -f1)
    line=$(echo "$selection" | cut -d: -f2)
    nvim +"$line" "$file"
  fi
}

# ── High-Speed Interactive Network Port Destroyer ─────────────────────
pkillf() {
  local port_line
  port_line=$(ss -tulnp 2>/dev/null | grep -v "Netid" | fzf \
    --height=40% \
    --reverse \
    --border=rounded \
    --prompt="🔌 Select Target Listen Port to Destroy ❯ ")

  if [[ -n "$port_line" ]]; then
    local pid
    pid=$(echo "$port_line" | grep -oE "pid=[0-9]+" | head -n 1 | cut -d= -f2)
    if [[ -n "$pid" ]]; then
      tui_status "Terminating socket group process PID: $pid"
      kill -9 "$pid" && tui_ok "Port vector cleared."
    else
      printf "\033[1;31m✘ Error:\033[0m Could not extract process identifier automatically.\n" >&2
    fi
  fi
}

# ── Instant Static Directory HTTP Server Matrix ────────────────────────
serve() {
  local port="${1:-8000}"
  if ! command -v python3 >/dev/null 2>&1; then
    printf "\033[1;31m✘ Error:\033[0m Python3 platform runtime not found.\n" >&2
    return 1
  fi

  printf "\033[1;32m⚡ Spinning Up Local Static HTTP Matrix Engine...\033[0m\n"
  printf " ├─ Local Address:  \033[1;34mhttp://localhost:%s\033[0m\n" "$port"
  if command -v hostname >/dev/null 2>&1; then
    printf " ├─ Net Interface: \033[1;34mhttp://$(hostname -I | awk '{print $1}'):%s\033[0m\n" "$port"
  fi
  printf " └─ Escape Command: \033[1;33mCtrl+C\033[0m to terminate listener server\n\n"

  python3 -m http.server "$port"
}

# ── Elite Core Config Architecture Quick-Jumper ──────────────────────
vconf() {
  local choice
  choice=$(printf "%s\n" \
    "⚙️ Zsh Core Configuration ➔ ~/.zshrc" \
    "🛠️ Zsh Extras Functions  ➔ ~/.zsh/dotfiles/functions/extras.zsh" \
    "🛸 Neovim Setup Core     ➔ ~/.config/nvim/init.lua" \
    "🧱 Tmux Control Layout   ➔ ~/.tmux.conf" | fzf \
      --height=40% --reverse --border=rounded --prompt="⚙️ Select Configuration File ❯ ")

  case "$choice" in
    *".zshrc"*)              nvim ~/.zshrc ;;
    *"extras.zsh"*)          nvim ~/.zsh/dotfiles/functions/extras.zsh ;;
    *"nvim/init.lua"*)       nvim ~/.config/nvim/init.lua ;;
    *".tmux.conf"*)          nvim ~/.tmux.conf ;;
  esac
}

# ── Advanced Git Commit Ledger Preview Matrix ──────────────────────────
glog() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf "\033[1;31m✘ Error:\033[0m Not inside an active git workspace.\n" >&2
    return 1
  fi

  local commit
  commit=$(git log --oneline --color=always | fzf \
    --ansi \
    --height=60% \
    --reverse \
    --border=rounded \
    --prompt="📜 Commit Ledger ❯ " \
    --header="Enter views changes / Ctrl+C to escape" \
    --preview="git show --color=always \$(echo {} | awk '{print \$1}')")

  if [[ -n "$commit" ]]; then
    local sha
    sha=$(echo "$commit" | awk '{print $1}')
    git show "$sha" | less -R
  fi
}

# ── Interactive File Explorer & Quick-Edit Engine ─────────────────────────────
fo() {
  local storage_file
  storage_file=$(find . -maxdepth 4 -type f -not -path '*/.*' -not -path './node_modules*' 2>/dev/null | fzf \
    --height=50% \
    --reverse \
    --border=rounded \
    --prompt="📂 Select Target Document ❯ " \
    --header="Type to filter file assets / Enter opens in editor" \
    --preview="head -n 40 {}")

  if [[ -n "$storage_file" ]]; then
    nvim "$storage_file"
  fi
}

# ── Atomic Git Commit Rollback & Undo Vector ──────────────────────────────────
gundo() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf "\033[1;31m✘ Error:\033[0m Local runtime is unversioned.\n" >&2
    return 1
  fi

  local last_commit
  last_commit=$(git log -1 --oneline --color=always 2>/dev/null)
  
  if [[ -z "$last_commit" ]]; then
    printf "\033[1;33m⚠ No commits detected inside this repository branch.\033[0m\n"
    return 0
  fi

  printf "\033[1;31m⚠ Prepared to softly dissolve the latest commit wrapper:\033[0m\n %s\n" "$last_commit"
  printf "\033[1;34m⚡ Code modifications will be preserved in your staging layout. Proceed? (y/N): \033[0m"
  read -r confirmation

  if [[ "$confirmation" =~ ^[Yy]$ ]]; then
    git reset --soft HEAD~1
    tui_ok "Commit dissolved. Modded layouts shifted back to the staging matrix."
  else
    printf "\033[1;32m✔\033[0m Operation aborted. Ledger intact.\n"
  fi
}

# ── High-Speed HTTP Header Telemetry Lens ─────────────────────────────────────
chead() {
  local target="${1:-localhost:8080}"
  if [[ "$target" != http* ]]; then
    target="http://$target"
  fi

  printf "\033[1;34m🛰️ intercepting header telemetry matrix from: %s\033[0m\n\n" "$target"
  curl -s -I -L "$target" | awk '
    /HTTP\//       {print "\033[1;32m" $0 "\033[0m"; next}
    /Server:|date:/ {print "\033[1;36m" $0 "\033[0m"; next}
    /Content-/     {print "\033[1;33m" $0 "\033[0m"; next}
    {print}
  '
}

# ── Dynamic Workspace Directory Archive Compressor ────────────────────────────
pack() {
  local target_dir="${1:-.}"
  if [[ ! -d "$target_dir" ]]; then
    printf "\033[1;31m✘ Error:\033[0m Select a valid structural directory path.\n" >&2
    return 1
  fi

  local base_name
  base_name=$(basename "$(real_path=$(cd "$target_dir" && pwd) && echo "$real_path")")
  local timestamp
  timestamp=$(date +%Y%m%d)
  local output_archive="${base_name}_matrix_${timestamp}.tar.gz"

  tui_status "Packing archive structure: $output_archive"
  tar -czf "$output_archive" --exclude="node_modules" --exclude=".git" --exclude=".venv" -C "$(dirname "$target_dir")" "$base_name"

  if [[ -f "$output_archive" ]]; then
    tui_ok "Compression engine complete: $(du -sh "$output_archive" | awk '{print $1}') allocated to disk."
  fi
}

# ── Unified Core TUI Feedback Component Engine ────────────────────────────────
tui_status() { printf "\r\033[K\033[1;34m⬢ [Telemetry]\033[0m %s...\n" "$1"; }
tui_ok()     { printf "\r\033[K\033[1;32m✔ [Success]\033[0m   %s\n" "$1"; }
tui_warn()   { printf "\r\033[K\033[1;33m⚠ [Warning]\033[0m   %s\n" "$1"; }
tui_fail()   { printf "\r\033[K\033[1;31m✘ [Failure]\033[0m   %s\n" "$1" >&2; }

# Dynamic micro-spinner overlay wrapper for background tasks
tui_wait() {
  local pid=$1
  local message=$2
  local delay=0.1
  local spinstr='⬢⬡'
  printf "\033[1;34m⏳ %s...\033[0m" "$message"
  while ps -p "$pid" >/dev/null 2>&1; do
    local temp=${spinstr#?}
    printf " \033[1;36m%c\033[0m" "$spinstr"
    spinstr=$temp${spinstr%"$temp"}
    sleep "$delay"
    printf "\b\b"
  done
  printf "\r\033[K"
}

# ── Dynamic Command Runtime Execution Telemetry ───────────────────────────────
_vtime_preexec() {
  _vtime_start_time=$EPOCHREALTIME
}

_vtime_precmd() {
  if [[ -n "$_vtime_start_time" ]]; then
    local end_time=$EPOCHREALTIME
    local elapsed
    # Calculate delta block
    elapsed=$((end_time - _vtime_start_time))
    if (( elapsed >= 1.0 )); then
      # Format presentation string into a crisp visual badge
      printf "\033[1;30m➔ Matrix Execution: %.2fs\033[0m\n" "$elapsed"
    fi
    unset _vtime_start_time
  fi
}

# Register lifecycle wrappers natively to Zsh arrays safely
autoload -Uz add-zsh-hook
add-zsh-hook preexec _vtime_preexec
add-zsh-hook precmd _vtime_precmd

# ── High-Visibility ANSI Color Grid Palette Matrix ────────────────────────────
vcolors() {
  printf "\033[1;34m🎨 Verifying Terminal True-Color Engine Mapping:\033[0m\n\n"
  local standard_colors=(31 32 33 34 35 36 37)
  
  printf " ├─ Core Primary Channels: "
  for color in "${standard_colors[@]}"; do
    printf "\033[%sm⬢ \033[0m" "$color"
  done
  printf "\n └─ 256-Color Extended Spectrum Grid:\n"

  # Iterates down numerical index rows to cleanly isolate code blocks
  for i in {0..7}; do
    printf "    "
    for j in {0..31}; do
      local n=$((i * 32 + j))
      if (( n <= 255 )); then
        printf "\033[48;5;%sm \033[0m" "$n"
      fi
    done
    echo ""
  done
}

# ── Interactive Command Syntax Cheat-Sheet Matrix ─────────────────────
cheat() {
  local language_cmd="$1"
  if [[ -z "$language_cmd" ]]; then
    printf "\033[1;34m💡 Quick-Syntax Core Query (e.g., python/read file) ❯ \033[0m"
    read -r language_cmd
  fi
  
  if [[ -n "$language_cmd" ]]; then
    tui_status "Querying global cheat-sheet grid for: $language_cmd"
    # Pulls syntax documentation with standard Monokai color formatting
    curl -s "https://cht.sh/${language_cmd}?style=monokai" | less -R
  fi
}

# ── High-Visibility Hardware Metrics Diagnostic ───────────────────────
sysinfo() {
  printf "\033[1;34m💻 Infrastructure Hardware Matrix Telemetry:\033[0m\n"
  
  local load
  load=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ //')
  printf " ├─ Load Average: \033[1;36m%s\033[0m\n" "$load"
  
  if command -v free >/dev/null 2>&1; then
    free -h | awk '/Mem:/ {printf " ├─ Memory Pool:  Used: %s / Total: %s (Free: %s)\n", $3, $2, $4}'
  fi
  
  # Battery extraction matrix for portable hardware ecosystems
  if [[ -d /sys/class/power_supply/BAT0 ]]; then
    local bat_cap bat_stat
    bat_cap=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
    bat_stat=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)
    printf " └─ Power Status: \033[1;32m%s%%\033[0m [%s]\n" "$bat_cap" "$bat_stat"
  else
    printf " └─ Power Status: \033[1;30mAC Grid/Container Bound\033[0m\n"
  fi
}

# ── Deep Build Artifact Purge & Space Recovery Matrix ─────────────────
vclean() {
  tui_warn "Preparing directory sweep for temporary cache artifacts..."
  
  local pycache_count log_count
  pycache_count=$(find . -type d -name "__pycache__" 2>/dev/null | wc -l | tr -d ' ')
  log_count=$(find . -type f -name "*.log" -maxdepth 3 2>/dev/null | wc -l | tr -d ' ')
  
  printf " ├─ Identified %s __pycache__ groups\n" "$pycache_count"
  printf " ├─ Identified %s local log file streams\n" "$log_count"
  printf "\033[1;34m⚡ Execute recursive data purge? (y/N): \033[0m"
  read -r confirm
  
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
    find . -type f -name "*.log" -maxdepth 3 -delete 2>/dev/null
    tui_ok "Workspace garbage vacuum complete. Sectors optimized."
  else
    tui_status "Purge vector cancelled. Structure left intact."
  fi
}

# ── Hard Profile Runtime Refresh Matrix ───────────────────────────────
vreload() {
  tui_status "Re-initializing absolute environment lifecycle"
  
  if [[ -f ~/.zshrc ]]; then
    # Spawns a minor background delay thread to show off the geometric micro spinner
    sleep 0.6 &
    tui_wait $! "Compiling current dotfile layers into runtime memory"
    exec zsh
    tui_ok "Shell profile reloaded cleanly."
  else
    tui_fail "Zsh shell core configuration not visible at path targets."
  fi
}

# ── Sandboxed Interactive Micro-Note Engine ───────────────────────────────────
memo() {
  local memo_dir="$HOME/.zsh/dotfiles/.memos"
  mkdir -p "$memo_dir"

  local target_memo
  target_memo=$(find "$memo_dir" -type f -name "*.md" 2>/dev/null | sed "s|$memo_dir/||" | fzf \
    --height=40% \
    --reverse \
    --border=rounded \
    --prompt="📝 Select or Create Memo Vector ❯ " \
    --header="Enter opens note / Type a unique name to initialize fresh file")

  # If nothing was selected but the user typed input, use that string as a new filename
  if [[ -z "$target_memo" ]]; then
    return 0
  fi

  # Append extension if not explicitly typed by user
  if [[ "$target_memo" != *.md ]]; then
    target_memo="${target_memo}.md"
  fi

  nvim "$memo_dir/$target_memo"
}

# ── Smart Multi-Format Archive Decompressor ───────────────────────────────────
unpack() {
  local target_archive="$1"
  if [[ -z "$target_archive" ]]; then
    tui_fail "Specify a valid archive structure parameter."
    return 1
  fi

  if [[ ! -f "$target_archive" ]]; then
    tui_fail "Target payload file path target does not exist: $target_archive"
    return 1
  fi

  tui_status "Analyzing compilation formatting wrapper"
  case "$target_archive" in
    *.tar.gz|*.tgz) tar -xzf "$target_archive"   && tui_ok "Extracted via Gzip Tar compression matrix." ;;
    *.tar.bz2|*.tbz2) tar -xjf "$target_archive" && tui_ok "Extracted via Bzip2 Tar compression matrix." ;;
    *.tar) tar -xf "$target_archive"             && tui_ok "Extracted raw tape archive sequence cleanly." ;;
    *.zip) unzip "$target_archive" >/dev/null    && tui_ok "Extracted via Standard Zip protocol archive." ;;
    *.rar) unrar x "$target_archive"             && tui_ok "Extracted Roshal Archive configuration allocation." ;;
    *) tui_fail "Archive structure allocation parsing protocol not supported." ;;
  esac
}

# ── Local Listener Port Deep-Investigation Audit ──────────────────────────────
vports() {
  printf "\033[1;34m🔌 Mapping Active Listening Interfaces & Process Owners:\033[0m\n\n"
  
  if ! command -v ss >/dev/null 2>&1; then
    tui_fail "Socket diagnostic binary ('ss') is unavailable in this environment subsystem."
    return 1
  fi

  printf " %-8s %-7s %-20s %-s\n" "PROTOCOL" "PORT" "LOCAL ADDR" "PROCESS PROCESSOR OWNER"
  printf " %-8s %-7s %-20s %-s\n" "--------" "----" "----------" "-----------------------"
  
  ss -tulnp 2>/dev/null | sed 1d | awk '
    {
      split($5, addr, ":");
      port = addr[length(addr)];
      proto = $1;
      local_ip = $5;
      
      # Extract process token names gracefully out of string layers
      match($7, /users:\(\("([^"]+)",pid=([0-9]+)/, m);
      proc_name = (m[1] != "") ? m[1] : "System/Kernel";
      pid = (m[2] != "") ? m[2] : "N/A";
      
      printf " \033[1;32m%-8s\033[0m %-7s %-20s \033[1;36m%s\033[0m (PID: %s)\n", proto, port, local_ip, proc_name, pid
    }
  '
}

# ── High-Speed Interactive JSON Payload Filter ────────────────────────────────
vjson() {
  if ! command -v jq >/dev/null 2>&1; then
    tui_fail "JSON parser processing utility ('jq') is missing from the environment."
    return 1
  fi

  local json_file
  json_file=$(find . -maxdepth 3 -type f -name "*.json" 2>/dev/null | fzf \
    --height=50% --reverse --border=rounded --prompt="🧱 Select Target JSON Object ❯ ")

  if [[ -n "$json_file" ]]; then
    printf "\033[1;34m⚡ Visualized Mapping Structure for: %s\033[0m\n" "$json_file"
    printf "\033[1;30m💡 Tip: Esc or Ctrl+C drops back out to core runtime prompt line\033[0m\n\n"
    jq -C . "$json_file" | less -R
  fi
}

# ── Custom Workspace Central Help Matrix Dashboard ────────────────────────────
help() {
  printf "\033[1;34m⬢ ── CUSTOM TERMINAL WORKSPACE MATRIX INDEX ── ⬢\033[0m\n\n"

  printf "\033[1;35m📦 WORKSPACE & NAVIGATION MULTIPLEXING\033[0m\n"
  printf " ├─ \033[1;32msess\033[0m    ➔ Interactive tmux session picker / multiplexer manager\n"
  printf " ├─ \033[1;32mtre\033[0m     ➔ Deep directory architect mapper layout (tree fallback)\n"
  printf " ├─ \033[1;32mfo\033[0m      ➔ Interactive file explorer and Neovim automatic opener\n"
  printf " └─ \033[1;32mvconf\033[0m   ➔ Core configuration profile directory jumper matrix\n\n"

  printf "\033[1;36m🌿 SOURCE CONTROL & DEPLOYMENT UTILITIES\033[0m\n"
  printf " ├─ \033[1;32mgdiff\033[0m   ➔ Interactive side-by-side git preview and file editor\n"
  printf " ├─ \033[1;32mglog\033[0m    ➔ Split-screen git commit log ledger and diff review\n"
  printf " ├─ \033[1;32mgcm\033[0m     ➔ Conventional commit message architect formatter\n"
  printf " ├─ \033[1;32mgundo\033[0m   ➔ Atomic soft git commit rollback (preserves staging changes)\n"
  printf " └─ \033[1;32mdkl\033[0m     ➔ Interactive Docker container selector & log telemetry streamer\n\n"

  printf "\033[1;33m🌐 METRICS, NETWORK & DIAGNOSTICS\033[0m\n"
  printf " ├─ \033[1;32mmyip\033[0m    ➔ Container network bridge mapper & WAN geolocation scanner\n"
  printf " ├─ \033[1;32mvports\033[0m  ➔ Listening TCP/UDP port socket mapping and PID owner audit\n"
  printf " ├─ \033[1;32mchead\033[0m   ➔ Clean HTTP header telemetry viewer and response validator\n"
  printf " ├─ \033[1;32mhogs\033[0m    ➔ Real-time CPU and Memory allocation tracker tables\n"
  printf " └─ \033[1;32msysinfo\033[0m ➔ General hardware diagnostic, container bounds, and load logs\n\n"

  printf "\033[1;31m⚙️ DEVELOPMENT RUNTIMES & SYSTEM ACCELERATORS\033[0m\n"
  printf " ├─ \033[1;32mrgf\033[0m     ➔ Global ripgrep string matching wizard with instant file jumps\n"
  printf " ├─ \033[1;32mhs\033[0m      ➔ Deep interactive command line memory index history log tool\n"
  printf " ├─ \033[1;32mrun\033[0m     ➔ Transient python/node compiler sandbox scratchpad\n"
  printf " ├─ \033[1;32mcheat\033[0m   ➔ In-terminal programming syntax cheat-sheet collector\n"
  printf " ├─ \033[1;32mvjson\033[0m   ➔ Dynamic JSON payload validator and pager interface parser\n"
  printf " ├─ \033[1;32mpkillf\033[0m  ➔ Direct listening network interface process destroyer\n"
  printf " ├─ \033[1;32mpack\033[0m    ➔ Tarball directory backup compressor excluding node modules\n"
  printf " ├─ \033[1;32munpack\033[0m  ➔ Smart multi-format binary/archive payload extractor\n"
  printf " ├─ \033[1;32mvclean\033[0m  ➔ Deep cache cleaner and pycache sweeping utility\n"
  printf " ├─ \033[1;32mvcolors\033[0m ➔ True-color terminal palette validation grid spectrum\n"
  printf " └─ \033[1;32mvreload\033[0m ➔ Hot-compiles environment configuration variables live\n\n"

  printf "\033[1;30m💡 Tip: Type any command name above to execute its tactical routine matrix.\033[0m\n"
}

# Create a clean single-character alias for rapid dashboard execution
alias h="help"

# ── Interactive Git Branch Matrix Switcher ────────────────────────────────────
gb() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    tui_fail "Current workspace is unversioned by git software."
    return 1
  fi

  local branch
  branch=$(git branch --all | grep -v 'HEAD ->' | sed 's/remotes\/origin\///' | sort -u | fzf \
    --height=40% \
    --reverse \
    --border=rounded \
    --prompt="🌿 Select Target Branch Vector ❯ ")

  if [[ -n "$branch" ]]; then
    # Strip whitespace formatting tokens cleanly
    branch=$(echo "$branch" | tr -d ' *')
    tui_status "Shifting codebase working files to branch: $branch"
    git checkout "$branch" && tui_ok "Target checkout operational context achieved."
  fi
}

# ── Cryptographic Base64 Data Transformation Engine ───────────────────────────
b64() {
  local choice input
  choice=$(printf "%s\n" "🔒 Encode Standard Text String ➔ Base64" "🔓 Decode Base64 Raw Hash ➔ Text String" | fzf \
    --height=30% --reverse --border=rounded --prompt="⚡ Select Transformation Vector ❯ ")

  if [[ -z "$choice" ]]; then return 0; fi

  printf "\033[1;34m📝 Input objective text data stream: \033[0m"
  read -r input

  if [[ -z "$input" ]]; then return 0; fi

  if [[ "$choice" == *"Encode"* ]]; then
    printf " └─ Output: \033[1;32m%s\033[0m\n" "$(echo -n "$input" | base64)"
  else
    printf " └─ Output: \033[1;36m%s\033[0m\n" "$(echo -n "$input" | base64 --decode 2>/dev/null || echo -e '\033[1;31mError: Invalid Hash\033[0m')"
  fi
}

# ── Local Workspace Task Tracker Matrix ───────────────────────────────────────
vtodo() {
  local todo_file=".vtodo"
  touch "$todo_file"
  
  local action
  action=$(printf "%s\n" "📋 View / Complete Active Items" "➕ Add New Task Target" | fzf \
    --height=30% --reverse --border=rounded --prompt="⚡ Select Todo Matrix Operation ❯ ")

  if [[ -z "$action" ]]; then return 0; fi

  if [[ "$action" == *"Add"* ]]; then
    printf "\033[1;34m➕ Input target milestone description: \033[0m"
    read -r description
    if [[ -n "$description" ]]; then
      echo "[ ] $description ($(date +'%Y-%m-%d %H:%M'))" >> "$todo_file"
      tui_ok "Task line cleanly registered to project tracking file."
    fi
  else
    if [[ ! -s "$todo_file" ]]; then
      tui_status "Workspace agenda manifest queue is empty."
      return 0
    fi

    local selection
    selection=$(nl -w2 -s'. ' "$todo_file" | fzf --height=40% --reverse --border=rounded --prompt="📋 Select Task to Resolve ❯ ")
    if [[ -n "$selection" ]]; then
      local line_num
      line_num=$(echo "$selection" | awk '{print $1}' | tr -d '.')
      sed -i "${line_num}d" "$todo_file"
      tui_ok "Task verified, processed, and dissolved from ledger."
    fi
  fi
}

# ── High-Speed Color-Preserving Live Output Watcher ───────────────────────────
vwatch() {
  local monitor_cmd="$*"
  if [[ -z "$monitor_cmd" ]]; then
    tui_fail "Supply an execution command loop string. Usage: vwatch <cmd>"
    return 1
  fi

  printf "\033[1;34m⏳ Intercepting output signals for: \033[1;33m%s\033[0m\n" "$monitor_cmd"
  printf "\033[1;30m💡 Terminal loop running. Strike Ctrl+C to drop tracking session\033[0m\n\n"
  sleep 1

  while true; do
    clear
    printf "\033[1;30m⏱️ Matrix Stream Update: %s\033[0m\n\n" "$(date +%H:%M:%S)"
    eval "$monitor_cmd"
    sleep 2
  done
}

# ── All-Inclusive Custom Workspace Matrix Index Dashboard ─────────────────────
help() {
  printf "\033[1;34m⬢ ── CUSTOM TERMINAL WORKSPACE MATRIX INDEX ── ⬢\033[0m\n\n"

  printf "\033[1;35m📦 WORKSPACE & NAVIGATION MULTIPLEXING\033[0m\n"
  printf " ├─ \033[1;32msess\033[0m    ➔ Interactive tmux session picker / multiplexer manager\n"
  printf " ├─ \033[1;32mtre\033[0m     ➔ Deep directory architect mapper layout (tree fallback)\n"
  printf " ├─ \033[1;32mfo\033[0m      ➔ Interactive file explorer and Neovim automatic opener\n"
  printf " ├─ \033[1;32mmemo\033[0m    ➔ Sandboxed interactive markdown micro-note workspace\n"
  printf " └─ \033[1;32mvconf\033[0m   ➔ Core configuration profile directory jumper matrix\n\n"

  printf "\033[1;36m🌿 SOURCE CONTROL & DEPLOYMENT UTILITIES\033[0m\n"
  printf " ├─ \033[1;32mgdiff\033[0m   ➔ Interactive side-by-side git preview and file editor\n"
  printf " ├─ \033[1;32mglog\033[0m    ➔ Split-screen git commit log ledger and diff review\n"
  printf " ├─ \033[1;32mgcm\033[0m     ➔ Conventional commit message architect formatter\n"
  printf " ├─ \033[1;32mgb\033[0m      ➔ Interactive git branch matrix switcher wizard\n"
  printf " ├─ \033[1;32mgundo\033[0m   ➔ Atomic soft git commit rollback (preserves staging changes)\n"
  printf " └─ \033[1;32mdkl\033[0m     ➔ Interactive Docker container selector & log telemetry streamer\n\n"

  printf "\033[1;33m🌐 METRICS, NETWORK & DIAGNOSTICS\033[0m\n"
  printf " ├─ \033[1;32mmyip\033[0m    ➔ Container network bridge mapper & WAN geolocation scanner\n"
  printf " ├─ \033[1;32mvports\033[0m  ➔ Listening TCP/UDP port socket mapping and PID owner audit\n"
  printf " ├─ \033[1;32mchead\033[0m   ➔ Clean HTTP header telemetry viewer and response validator\n"
  printf " ├─ \033[1;32mhogs\033[0m    ➔ Real-time CPU and Memory allocation tracker tables\n"
  printf " └─ \033[1;32msysinfo\033[0m ➔ General hardware diagnostic, container bounds, and load logs\n\n"

  printf "\033[1;31m⚙️ DEVELOPMENT RUNTIMES & SYSTEM ACCELERATORS\033[0m\n"
  printf " ├─ \033[1;32mrgf\033[0m     ➔ Global ripgrep string matching wizard with instant file jumps\n"
  printf " ├─ \033[1;32mhs\033[0m      ➔ Deep interactive command line memory index history log tool\n"
  printf " ├─ \033[1;32mvps\033[0m     ➔ Interactive background process inspector and manager tool\n"
  printf " ├─ \033[1;32mvenv\033[0m    ➔ Interactive shell environment variable registry lens\n"
  printf " ├─ \033[1;32mvssh\033[0m    ➔ Secure SSH key fingerprint identity registry explorer\n"
  printf " ├─ \033[1;32mrun\033[0m     ➔ Transient python/node compiler sandbox scratchpad\n"
  printf " ├─ \033[1;32mcheat\033[0m   ➔ In-terminal programming syntax cheat-sheet collector\n"
  printf " ├─ \033[1;32mvjson\033[0m   ➔ Dynamic JSON payload validator and pager interface parser\n"
  printf " ├─ \033[1;32mb64\033[0m     ➔ Cryptographic Base64 text stream data translator\n"
  printf " ├─ \033[1;32mvtodo\033[0m   ➔ Local localized workspace target milestone agenda tracker\n"
  printf " ├─ \033[1;32mvwatch\033[0m  ➔ High-speed color-preserving continuous execution output monitor\n"
  printf " ├─ \033[1;32mpkillf\033[0m  ➔ Direct listening network interface process destroyer\n"
  printf " ├─ \033[1;32mpack\033[0m    ➔ Tarball directory backup compressor excluding node modules\n"
  printf " ├─ \033[1;32munpack\033[0m  ➔ Smart multi-format binary/archive payload extractor\n"
  printf " ├─ \033[1;32mvclean\033[0m  ➔ Deep cache cleaner and pycache sweeping utility\n"
  printf " ├─ \033[1;32mvcolors\033[0m ➔ True-color terminal palette validation grid spectrum\n"
  printf " └─ \033[1;32mvreload\033[0m ➔ Hot-compiles environment configuration variables live\n\n"

  printf "\033[1;30m💡 Tip: Type any command name above to execute its tactical routine matrix.\033[0m\n"
}
