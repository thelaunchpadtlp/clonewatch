#!/usr/bin/env bash
# =============================================================================
# watch-sessions.sh — Live session watcher (no fswatch required)
# =============================================================================
# Polls session directories and triggers re-harvest when files change.
# Uses macOS stat for change detection — no external dependencies.
#
# Usage:
#   ./watch-sessions.sh                    # watch all enabled agents (60s interval)
#   ./watch-sessions.sh --interval 30      # custom poll interval in seconds
#   ./watch-sessions.sh --agent claude-code # specific agent only
#   ./watch-sessions.sh --once             # run one check and exit (good for cron)
#   ./watch-sessions.sh --install-launchd  # install as macOS background service
#   ./watch-sessions.sh --uninstall-launchd
#
# Launchd service (when installed):
#   Label: com.thelaunchpadtlp.clonewatch.session-watch
#   Runs: every 5 minutes automatically in the background
#   Logs: ~/Library/Logs/clonewatch-session-watch.log
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG="$SCRIPT_DIR/sessions-config.json"
HARVEST_SCRIPT="$SCRIPT_DIR/harvest-sessions.sh"

INTERVAL=60
AGENT_FILTER=""
ONCE=false
ACTION="watch"
LAUNCHD_LABEL="com.thelaunchpadtlp.clonewatch.session-watch"
LAUNCHD_PLIST="${HOME}/Library/LaunchAgents/${LAUNCHD_LABEL}.plist"
LOG_FILE="${HOME}/Library/Logs/clonewatch-session-watch.log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "[$(date '+%H:%M:%S')] ${BLUE}[watch]${NC} $*"; }
ok()   { echo -e "[$(date '+%H:%M:%S')] ${GREEN}[ok]${NC} $*"; }
warn() { echo -e "[$(date '+%H:%M:%S')] ${YELLOW}[warn]${NC} $*"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --interval) INTERVAL="$2"; shift 2 ;;
    --agent) AGENT_FILTER="$2"; shift 2 ;;
    --once) ONCE=true; shift ;;
    --install-launchd) ACTION="install"; shift ;;
    --uninstall-launchd) ACTION="uninstall"; shift ;;
    --help|-h) grep '^#' "$0" | sed 's/^# \{0,2\}//'; exit 0 ;;
    *) shift ;;
  esac
done

# ── Install launchd plist ─────────────────────────────────────────────────────
if [[ "$ACTION" == "install" ]]; then
  mkdir -p "${HOME}/Library/LaunchAgents" "${HOME}/Library/Logs"
  cat > "$LAUNCHD_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LAUNCHD_LABEL}</string>

  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${SCRIPT_DIR}/watch-sessions.sh</string>
    <string>--once</string>
  </array>

  <key>WorkingDirectory</key>
  <string>${REPO_ROOT}</string>

  <key>StartInterval</key>
  <integer>300</integer>

  <key>StandardOutPath</key>
  <string>${LOG_FILE}</string>

  <key>StandardErrorPath</key>
  <string>${LOG_FILE}</string>

  <key>RunAtLoad</key>
  <true/>

  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/usr/local/bin:/opt/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    <key>HOME</key>
    <string>${HOME}</string>
  </dict>
</dict>
</plist>
EOF
  launchctl load "$LAUNCHD_PLIST" 2>/dev/null || launchctl bootstrap gui/"$(id -u)" "$LAUNCHD_PLIST" 2>/dev/null || true
  echo "✅ Installed: $LAUNCHD_LABEL"
  echo "   Runs every 5 minutes. Logs: $LOG_FILE"
  echo "   To check status: launchctl list | grep clonewatch"
  echo "   To uninstall: $0 --uninstall-launchd"
  exit 0
fi

if [[ "$ACTION" == "uninstall" ]]; then
  launchctl unload "$LAUNCHD_PLIST" 2>/dev/null || launchctl bootout gui/"$(id -u)" "$LAUNCHD_PLIST" 2>/dev/null || true
  rm -f "$LAUNCHD_PLIST"
  echo "✅ Uninstalled: $LAUNCHD_LABEL"
  exit 0
fi

# ── Change detection state ────────────────────────────────────────────────────
declare -A LAST_SEEN_SIZE LAST_SEEN_MTIME

file_mtime()      { stat -f %m "$1" 2>/dev/null || echo 0; }
file_size_bytes() { stat -f %z "$1" 2>/dev/null || echo 0; }

scan_agent() {
  local agent_id="$1"
  local source_paths
  source_paths="$(jq -r ".agents[] | select(.id == \"$agent_id\") | .source_paths[]" "$CONFIG" 2>/dev/null | sed "s|~|$HOME|g")"

  local changed=false

  while IFS= read -r source_path; do
    [[ -d "$source_path" ]] || continue
    while IFS= read -r session_file; do
      [[ -f "$session_file" ]] || continue
      local key="${agent_id}:${session_file}"
      local current_size current_mtime
      current_size="$(file_size_bytes "$session_file")"
      current_mtime="$(file_mtime "$session_file")"

      if [[ "${LAST_SEEN_SIZE[$key]+_}" ]] && \
         [[ "${LAST_SEEN_SIZE[$key]}" != "$current_size" || "${LAST_SEEN_MTIME[$key]}" != "$current_mtime" ]]; then
        local delta=$(( current_size - ${LAST_SEEN_SIZE[$key]} ))
        warn "Changed: $agent_id — $(basename "$session_file") (+${delta} bytes)"
        changed=true
      fi
      LAST_SEEN_SIZE[$key]="$current_size"
      LAST_SEEN_MTIME[$key]="$current_mtime"
    done < <(find "$source_path" -name "*.jsonl" -not -path "*/session_index*" 2>/dev/null)
  done <<< "$source_paths"

  echo "$changed"
}

check_and_harvest() {
  local any_changed=false

  while IFS= read -r agent_json; do
    local agent_id enabled
    agent_id="$(echo "$agent_json" | jq -r '.id')"
    enabled="$(echo "$agent_json" | jq -r '.enabled')"
    [[ -n "$AGENT_FILTER" && "$agent_id" != "$AGENT_FILTER" ]] && continue
    [[ "$enabled" == "false" && -z "$AGENT_FILTER" ]] && continue

    local changed
    changed="$(scan_agent "$agent_id")"
    [[ "$changed" == "true" ]] && any_changed=true
  done < <(jq -c '.agents[]' "$CONFIG")

  if [[ "$any_changed" == "true" ]]; then
    log "Changes detected — triggering harvest..."
    local harvest_args=()
    [[ -n "$AGENT_FILTER" ]] && harvest_args+=(--agent "$AGENT_FILTER")
    bash "$HARVEST_SCRIPT" "${harvest_args[@]}" 2>&1 | grep -E '\[new\]|\[updated\]|\[warn\]|\[ok\]|Error|error' || true
    ok "Harvest complete."
  fi
}

# ── Main loop ─────────────────────────────────────────────────────────────────
if [[ "$ONCE" == true ]]; then
  # --once mode: just run harvest if any session file changed since last archive
  log "Running one-time check (--once mode)..."
  harvest_args=()
  [[ -n "$AGENT_FILTER" ]] && harvest_args+=(--agent "$AGENT_FILTER")
  bash "$HARVEST_SCRIPT" "${harvest_args[@]}" 2>&1
  exit 0
fi

log "Session watcher started (interval: ${INTERVAL}s)"
log "Watching agents: ${AGENT_FILTER:-all enabled}"
log "Press Ctrl+C to stop."
echo ""

# Initial scan to populate baseline
while IFS= read -r agent_json; do
  agent_id="$(echo "$agent_json" | jq -r '.id')"
  enabled="$(echo "$agent_json" | jq -r '.enabled')"
  [[ -n "$AGENT_FILTER" && "$agent_id" != "$AGENT_FILTER" ]] && continue
  [[ "$enabled" == "false" && -z "$AGENT_FILTER" ]] && continue
  scan_agent "$agent_id" > /dev/null
done < <(jq -c '.agents[]' "$CONFIG")

ok "Baseline captured. Watching for changes every ${INTERVAL}s..."

while true; do
  sleep "$INTERVAL"
  check_and_harvest
done
