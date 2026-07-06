# =============================================================================
# functions/osrs.zsh — Production-Grade OSRS & Jagex Launcher Crostini Engine
# Optimized for: Low-latency rendering, aggressive memory constraints, I/O tuning
# =============================================================================

unalias osrs 2>/dev/null || true
unalias osrs-audit 2>/dev/null || true
unalias osrs-start 2>/dev/null || true
unalias osrs-accel 2>/dev/null || true
unalias osrs-bolt 2>/dev/null || true
unalias osrs-bolt-accel 2>/dev/null || true
unalias osrs-clean 2>/dev/null || true
unalias osrs-backup 2>/dev/null || true
unalias jagex-launcher 2>/dev/null || true

typeset -g OSRS_CONFIG_FILE="$HOME/.config/osrs/config.conf"

function _osrs_load_external_config {
  if [[ -f "$OSRS_CONFIG_FILE" ]]; then
    while IFS='=' read -r key value; do
      [[ "$key" =~ ^[[:space:]]*# ]] && continue
      [[ -z "$key" ]] && continue
      key="${key//[[:space:]]/}"
      value="${value#[[:space:]]}"
      value="${value%[[:space:]]}"
      value="${value%\"}"
      value="${value#\"}"
      value="${value%\'}"
      value="${value#\'}"
      case "$key" in
        OSRS_FLATPAK_APP_BOLT|OSRS_FLATPAK_APP_OFFICIAL|OSRS_BACKUP_DIR|OSRS_BACKUP_MAX_ARCHIVES|OSRS_RUNELITE_DIR|OSRS_RUNELITE_LOG_DIR|OSRS_WINE_PREFIX_DIR|OSRS_JAVA_XMS|OSRS_JAVA_XMX|OSRS_JVM_FLAGS|OSRS_PULSE_LATENCY_MSEC|OSRS_GDK_BACKEND)
          export "$key"="$value"
          ;;
      esac
    done < "$OSRS_CONFIG_FILE"
  fi
}

_osrs_load_external_config

if [[ -z ${+OSRS_FLATPAK_APP_BOLT} ]]; then
  typeset -g -r OSRS_FLATPAK_APP_BOLT="com.adamcake.Bolt"
fi
if [[ -z ${+OSRS_FLATPAK_APP_OFFICIAL} ]]; then
  typeset -g -r OSRS_FLATPAK_APP_OFFICIAL="com.jagexlauncher.JagexLauncher"
fi
if [[ -z ${+OSRS_BACKUP_DIR} ]]; then
  typeset -g -r OSRS_BACKUP_DIR="$HOME/.zsh/dotfiles/backups/osrs"
fi
if [[ -z ${+OSRS_BACKUP_MAX_ARCHIVES} ]]; then
  typeset -g -r OSRS_BACKUP_MAX_ARCHIVES=5
fi
if [[ -z ${+OSRS_RUNELITE_DIR} ]]; then
  typeset -g -r OSRS_RUNELITE_DIR="$HOME/.var/app/com.jagexlauncher.JagexLauncher/data/user_home/.runelite"
fi
if [[ -z ${+OSRS_RUNELITE_LOG_DIR} ]]; then
  typeset -g -r OSRS_RUNELITE_LOG_DIR="$OSRS_RUNELITE_DIR/logs"
fi
if [[ -z ${+OSRS_WINE_PREFIX_DIR} ]]; then
  typeset -g -r OSRS_WINE_PREFIX_DIR="$HOME/.wine"
fi
if [[ -z ${+OSRS_JAVA_XMS} ]]; then
  typeset -g -r OSRS_JAVA_XMS="512m"
fi
if [[ -z ${+OSRS_JAVA_XMX} ]]; then
  typeset -g -r OSRS_JAVA_XMX="2g"
fi
if [[ -z ${+OSRS_JVM_FLAGS} ]]; then
  typeset -g -r OSRS_JVM_FLAGS="-XX:+UseG1GC -XX:+UseStringDeduplication -XX:+AlwaysPreTouch"
fi

function _osrs_sanitize_env {
  if [[ -n "${_JAVA_OPTIONS:-}" ]]; then
    _JAVA_OPTIONS="${_JAVA_OPTIONS//[^ -~]/ }"
    export _JAVA_OPTIONS="${_JAVA_OPTIONS//  / }"
  fi
  if [[ -n "${JAVA_TOOL_OPTIONS:-}" ]]; then
    JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS//[^ -~]/ }"
    export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS//  / }"
  fi
}
_osrs_sanitize_env

function _osrs_has_cmd { command -v "$1" >/dev/null 2>&1; }
function _osrs_mkdirp { mkdir -p -- "$1" >/dev/null 2>&1 || return 1; }

function _osrs_exec {
  local -a cmd
  cmd=( "$@" )
  if _osrs_has_cmd ionice && _osrs_has_cmd nice; then
    {
      ionice -c 2 -n 0 nice -n -5 "${cmd[@]}"
    } >/dev/null 2>&1 || {
      ionice -c 2 -n 0 "${cmd[@]}" >/dev/null 2>&1 || {
        "${cmd[@]}" >/dev/null 2>&1
      }
    }
  elif _osrs_has_cmd ionice; then
    ionice -c 2 -n 0 "${cmd[@]}" >/dev/null 2>&1 || "${cmd[@]}" >/dev/null 2>&1
  else
    "${cmd[@]}" >/dev/null 2>&1
  fi
}

function _osrs_exec_bg {
  ( _osrs_exec "$@" ) &
}

function _osrs_is_client_running {
  pgrep -f 'com\.jagexlauncher\.JagexLauncher' >/dev/null 2>&1 && return 0
  pgrep -f 'com\.adamcake\.Bolt' >/dev/null 2>&1 && return 0
  pgrep -f 'RuneLite' >/dev/null 2>&1 && return 0
  return 1
}

function _osrs_clean_lock {
  local lock="/tmp/osrs_clean.lock"
  if [[ -e "$lock" ]]; then
    return 1
  fi
  : > "$lock" 2>/dev/null || return 1
  trap 'rm -f -- "$lock" 2>/dev/null' EXIT INT TERM
  return 0
}

function osrs_audit {
  echo -e "\n⬢================== OSRS SYSTEM AUDIT ==================\n"
  if _osrs_has_cmd glxinfo; then
    local renderer
    renderer=$(glxinfo | grep "OpenGL renderer" | cut -d: -f2 | xargs)
    echo "Graphics Renderer:  ${renderer}"
    if [[ "$renderer" == *"llvmpipe"* ]]; then
      echo "⚠️  STATUS: Software Rendering (SLOW). Enable Crostini GPU flag!"
    else
      echo "✅ STATUS: Hardware Accelerated."
    fi
  else
    echo "Graphics Renderer:  ❌ glxinfo not available."
  fi

  if _osrs_has_cmd free; then
    echo -e "\nMemory profile:"
    free -h 2>/dev/null || true
  fi

  echo -e "\nCPU scaling governors:"
  for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor(N); do
    [[ -r "$f" ]] && echo "  ${f%/scaling_governor##*/}: $(<"$f")"
  done 2>/dev/null || echo "  (cpufreq info unavailable)"

  echo -e "\nFlatpak configuration overrides:"
  if _osrs_has_cmd flatpak; then
    local official_dri=$(flatpak info --show-permissions "$OSRS_FLATPAK_APP_OFFICIAL" | grep "dri")
    local bolt_dri=$(flatpak info --show-permissions "$OSRS_FLATPAK_APP_BOLT" | grep "dri")
    if [[ -n "$official_dri" ]]; then
      echo "  Official Launcher:  ✅ /dev/dri accessible"
    else
      echo "  Official Launcher:  ❌ Sandbox is blocking GPU access"
    fi
    if [[ -n "$bolt_dri" ]]; then
      echo "  Bolt Launcher:      ✅ /dev/dri accessible"
    else
      echo "  Bolt Launcher:      ❌ Sandbox is blocking GPU access"
    fi
  else
    echo "  (flatpak binary missing)"
  fi

  echo -e "\nEnvironment Status:"
  echo "  JAVA_TOOL_OPTS:     ${JAVA_TOOL_OPTIONS:-Not Set}"
  if [[ -n "$_JAVA_OPTIONS" ]]; then
    echo "⚠️  WARNING: _JAVA_OPTIONS is set. We will clear this on launch."
  else
    echo "  _JAVA_OPTIONS:      ✅ Clean / Not Set"
  fi
  echo -e "\n⬢======================================================\n"
}

function osrs_backup {
  echo -e "\033[0;36m[*] Initializing RuneLite profile backup sequence...\033[0m"
  local target_dir="$OSRS_RUNELITE_DIR"
  if [[ ! -d "$target_dir" ]]; then
    local bolt_fallback="$HOME/.var/app/$OSRS_FLATPAK_APP_BOLT/data/user_home/.runelite"
    if [[ -d "$bolt_fallback" ]]; then
      target_dir="$bolt_fallback"
    else
      echo -e "\033[0;31m[✘] Error: RuneLite configurations not found.\033[0m"
      return 1
    fi
  fi

  _osrs_mkdirp "$OSRS_BACKUP_DIR" || return 1
  local ts archive
  ts="$(date +%Y%m%d-%H%M%S)"
  archive="$OSRS_BACKUP_DIR/runelite_profile_backup_$ts.tar.gz"

  tar -czf "$archive" \
    --exclude='*/cache/*' \
    --exclude='*/imagecache/*' \
    --exclude='*/logs/*' \
    --exclude='*/.runelite/screenshots/*' \
    --exclude='*/screenshots/*' \
    -C "$(dirname "$target_dir")" .runelite 2>/dev/null || return 1

  echo -e "\033[0;32m[✔] Archive created: $archive\033[0m"
  local -a archives
  archives=("${(@f)$(ls -1dt -- "$OSRS_BACKUP_DIR"/runelite_profile_backup_*.tar.gz(N) 2>/dev/null)}")
  if (( ${#archives[@]} > OSRS_BACKUP_MAX_ARCHIVES )); then
    rm -f -- "${archives[@]:OSRS_BACKUP_MAX_ARCHIVES}" 2>/dev/null || true
  fi
}

function osrs_clean {
  if _osrs_is_client_running; then
    echo -e "\033[0;31m[✘] Error: Close active OSRS clients first.\033[0m"
    return 1
  fi
  _osrs_clean_lock || return 1
  echo -e "\033[0;36m[*] Purging volatile cache layers...\033[0m"
  if [[ -d "$OSRS_RUNELITE_LOG_DIR" ]]; then
    find "$OSRS_RUNELITE_LOG_DIR" -type f \( -name "*.log" -o -name "*.txt" \) -mtime +14 -delete 2>/dev/null || true
  fi
  [[ -d "$OSRS_RUNELITE_DIR/cache" ]] && rm -rf -- "$OSRS_RUNELITE_DIR/cache" 2>/dev/null || true
  [[ -d "$OSRS_WINE_PREFIX_DIR/tmp" ]] && rm -rf -- "$OSRS_WINE_PREFIX_DIR/tmp" 2>/dev/null || true
  if _osrs_has_cmd flatpak; then
    flatpak uninstall --unused -y >/dev/null 2>&1 || true
  fi
  echo -e "\033[0;32m[✔] Deep prune operation complete. Quack!\033[0m"
}

function _osrs_jvm_opts {
  local opts="-Xms${OSRS_JAVA_XMS} -Xmx${OSRS_JAVA_XMX} ${OSRS_JVM_FLAGS}"
  opts="${opts//[^ -~]/ }"
  echo -n "${opts//  / }"
}

function _osrs_apply_gpu_overrides {
  if _osrs_has_cmd flatpak; then
    flatpak override --user --device=dri "$OSRS_FLATPAK_APP_OFFICIAL" > /dev/null 2>&1 || true
    flatpak override --user --device=dri "$OSRS_FLATPAK_APP_BOLT" > /dev/null 2>&1 || true
  fi
}

function osrs_launch {
  local target=$1
  local mode=$2
  local jvm_opts
  jvm_opts="$(_osrs_jvm_opts)"

  export GDK_BACKEND="${OSRS_GDK_BACKEND:-x11}"
  export SOMMELIER_ACCELERATORS="<Super>w"
  export vblank_mode=0
  export PULSE_LATENCY_MSEC="${OSRS_PULSE_LATENCY_MSEC:-60}"

  unset _JAVA_OPTIONS
  export JAVA_TOOL_OPTIONS="$jvm_opts"
  _osrs_sanitize_env

  local app_id="$OSRS_FLATPAK_APP_OFFICIAL"
  [[ "$target" == "bolt" ]] && app_id="$OSRS_FLATPAK_APP_BOLT"

  if [[ "$mode" == "accel" ]]; then
    _osrs_apply_gpu_overrides
    export GALLIUM_DRIVER=virgl
    _osrs_exec_bg flatpak run --unset-env=_JAVA_OPTIONS --env=WINE_GSTREAMER_IMMEDIATE_CONTEXT=1 --env=JAVA_TOOL_OPTIONS="$JAVA_TOOL_OPTIONS" "$app_id"
  else
    _osrs_exec_bg flatpak run --unset-env=_JAVA_OPTIONS --env=WINE_GSTREAMER_IMMEDIATE_CONTEXT=1 --env=libgl_always_software=true --env=JAVA_TOOL_OPTIONS="$JAVA_TOOL_OPTIONS" "$app_id" --disable-gpu --disable-gpu-sandbox --no-sandbox --disable-dev-shm-usage
  fi
  echo -e "\033[0;32m[✔] $target client dispatched (acceleration=$mode). Quack!\033[0m"
}

function osrs {
  case "${1:-}" in
    audit) shift; osrs_audit "$@" ;;
    clean) shift; osrs_clean "$@" ;;
    backup) shift; osrs_backup "$@" ;;
    bolt) shift; osrs_launch "bolt" "soft" "$@" ;;
    bolt-accel) shift; osrs_launch "bolt" "accel" "$@" ;;
    start) shift; osrs_launch "jagex" "soft" "$@" ;;
    start-accel) shift; osrs_launch "jagex" "accel" "$@" ;;
    *)
      echo "Usage: osrs {audit|clean|backup|start|start-accel|bolt|bolt-accel}"
      ;;
  esac
}

alias osrs-audit="osrs audit"
alias osrs-start="osrs start"
alias osrs-accel="osrs start-accel"
alias osrs-bolt="osrs bolt"
alias osrs-bolt-accel="osrs bolt-accel"
alias osrs-clean="osrs clean"
alias osrs-backup="osrs backup"
