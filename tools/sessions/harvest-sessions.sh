#!/usr/bin/env bash
# =============================================================================
# harvest-sessions.sh — CloneWatch Session Harvest Automation
# =============================================================================
# Discovers, imports, and incrementally updates agent session archives.
# Handles GROWING sessions: a session file that was harvested at 9am may have
# 3x more content by 11am. This script detects changes and re-harvests.
#
# Usage:
#   ./harvest-sessions.sh                     # harvest new + update changed
#   ./harvest-sessions.sh --agent claude-code # specific agent only
#   ./harvest-sessions.sh --since 2026-04-14  # only sessions from date onward
#   ./harvest-sessions.sh --force             # re-harvest everything regardless
#   ./harvest-sessions.sh --new-only          # only harvest sessions not yet in archive
#   ./harvest-sessions.sh --list              # list known agents
#   ./harvest-sessions.sh --status            # show what's archived and staleness
#   ./harvest-sessions.sh --dry-run           # preview without writing
#   ./harvest-sessions.sh --check-versions    # check if agent app versions changed
#
# How change detection works:
#   Each harvested session stores raw_size_bytes and raw_mtime_unix in metadata.json.
#   On next run, current file stats are compared. If either changed, the session
#   is re-harvested. The archive directory is kept but metadata.json and summary.md
#   are overwritten; harvest_count is incremented.
#
# Session status:
#   active     — file modified within last 60 minutes (session likely still running)
#   recent     — file modified within last 24 hours (recently finished)
#   completed  — file modified more than 24 hours ago
#   aging      — Claude Code sessions within 10 days of the 30-day cleanup window
#   expired    — Claude Code sessions past the 30-day window (should have been copied)
# =============================================================================

set -euo pipefail

# ── Paths ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG="$SCRIPT_DIR/sessions-config.json"
ARCHIVE_DIR="$REPO_ROOT/docs/sessions/archive"
INDEX_FILE="$REPO_ROOT/docs/sessions/index.md"
IMPORTERS_DIR="$SCRIPT_DIR/importers"

# ── Defaults ─────────────────────────────────────────────────────────────────
AGENT_FILTER=""
SINCE_DATE=""
DRY_RUN=false
FORCE=false
NEW_ONLY=false
ACTION="harvest"
TODAY="$(date -u +%Y-%m-%d)"
NOW_UNIX="$(date -u +%s)"

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

log()    { echo -e "${BLUE}[harvest]${NC} $*"; }
ok()     { echo -e "${GREEN}[ok]${NC} $*"; }
warn()   { echo -e "${YELLOW}[warn]${NC} $*"; }
update() { echo -e "${CYAN}[update]${NC} $*"; }
err()    { echo -e "${RED}[error]${NC} $*" >&2; }

# ── Arguments ─────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)         AGENT_FILTER="$2"; shift 2 ;;
    --since)         SINCE_DATE="$2"; shift 2 ;;
    --dry-run)       DRY_RUN=true; shift ;;
    --force)         FORCE=true; shift ;;
    --new-only)      NEW_ONLY=true; shift ;;
    --list)          ACTION="list"; shift ;;
    --status)        ACTION="status"; shift ;;
    --check-versions) ACTION="check-versions"; shift ;;
    --help|-h)       grep '^#' "$0" | sed 's/^# \{0,2\}//'; exit 0 ;;
    *) err "Unknown argument: $1"; exit 1 ;;
  esac
done

# ── Dependencies ─────────────────────────────────────────────────────────────
for cmd in jq python3; do
  if ! command -v "$cmd" &>/dev/null; then
    err "Required: $cmd — install with: sudo port install $cmd   or   brew install $cmd"
    exit 1
  fi
done

[[ -f "$CONFIG" ]] || { err "Config not found: $CONFIG"; exit 1; }

# ── Helper: file modification time as unix timestamp ─────────────────────────
file_mtime() { stat -f %m "$1" 2>/dev/null || echo 0; }
file_size_bytes() { stat -f %z "$1" 2>/dev/null || echo 0; }

# ── Helper: determine session status from mtime ───────────────────────────────
session_status() {
  local raw_path="$1"
  local agent_id="$2"
  local cleanup_days="${3:-}"
  [[ -f "$raw_path" ]] || { echo "missing"; return; }

  local mtime
  mtime="$(file_mtime "$raw_path")"
  local age_seconds=$(( NOW_UNIX - mtime ))
  local age_hours=$(( age_seconds / 3600 ))
  local age_days=$(( age_seconds / 86400 ))

  if [[ $age_seconds -lt 3600 ]]; then
    echo "active"
  elif [[ $age_hours -lt 24 ]]; then
    echo "recent"
  elif [[ -n "$cleanup_days" && "$cleanup_days" != "null" ]]; then
    local days_until_cleanup=$(( cleanup_days - age_days ))
    if [[ $days_until_cleanup -le 0 ]]; then
      echo "expired"
    elif [[ $days_until_cleanup -le 10 ]]; then
      echo "aging"
    else
      echo "completed"
    fi
  else
    echo "completed"
  fi
}

# ── Helper: check if archived session is stale ───────────────────────────────
is_stale() {
  local metadata_file="$1"
  local raw_path="$2"
  [[ -f "$raw_path" ]] || return 1  # raw gone → not stale, just missing
  [[ -f "$metadata_file" ]] || return 0  # no metadata → treat as stale

  local stored_mtime stored_size current_mtime current_size
  stored_mtime="$(jq -r '.raw_mtime_unix // 0' "$metadata_file" 2>/dev/null)"
  stored_size="$(jq -r '.raw_size_bytes // 0' "$metadata_file" 2>/dev/null)"
  current_mtime="$(file_mtime "$raw_path")"
  current_size="$(file_size_bytes "$raw_path")"

  # If metadata has no mtime/size fields → old format → treat as stale
  if [[ "$stored_mtime" == "0" && "$stored_size" == "0" ]]; then
    return 0
  fi

  # Stale if file is larger or newer
  if [[ "$current_size" -gt "$stored_size" ]] || [[ "$current_mtime" -gt "$stored_mtime" ]]; then
    return 0  # stale
  fi
  return 1  # not stale
}

# ── --list ───────────────────────────────────────────────────────────────────
if [[ "$ACTION" == "list" ]]; then
  echo ""; echo "Registered agents (sessions-config.json):"; echo ""
  jq -r '.agents[] | "  \(if .enabled then "✅" else "⬜" end) \(.id) — \(.display_name) | format=\(.format_id) | cleanup=\(.cleanup_days // "none")"' "$CONFIG"
  echo ""; exit 0
fi

# ── --status ─────────────────────────────────────────────────────────────────
if [[ "$ACTION" == "status" ]]; then
  echo ""; echo "Session archive status:"; echo ""
  FOUND=false
  while IFS= read -r f; do
    FOUND=true
    agent="$(jq -r '.agent_id' "$f" 2>/dev/null)"
    date="$(jq -r '.date' "$f" 2>/dev/null)"
    sid="$(jq -r '.session_id' "$f" 2>/dev/null | cut -c1-8)"
    raw="$(jq -r '.raw_path' "$f" 2>/dev/null)"
    count="$(jq -r '.harvest_count // 1' "$f" 2>/dev/null)"
    cleanup="$(jq -r '.cleanup_days_remaining // "?"' "$f" 2>/dev/null)"
    status="$(session_status "$raw" "$agent" "")"
    # Staleness check
    stale=""
    is_stale "$f" "$raw" && stale="${YELLOW}[STALE]${NC}"
    echo -e "  [$date] $agent — $sid... | harvested×$count | status=$status $stale"
  done < <(find "$ARCHIVE_DIR" -name "metadata.json" | sort -r 2>/dev/null)
  [[ "$FOUND" == false ]] && echo "  (no sessions harvested yet)"
  echo ""; exit 0
fi

# ── --check-versions ─────────────────────────────────────────────────────────
if [[ "$ACTION" == "check-versions" ]]; then
  bash "$SCRIPT_DIR/check-app-versions.sh" --config "$CONFIG"
  exit $?
fi

# ── Main harvest ─────────────────────────────────────────────────────────────
log "CloneWatch Session Harvest — $TODAY"
[[ "$DRY_RUN" == true ]] && warn "DRY RUN — no files written"
[[ "$FORCE" == true ]] && warn "FORCE mode — re-harvesting all sessions"
[[ "$NEW_ONLY" == true ]] && log "NEW_ONLY — skipping staleness check"
echo ""

NEW=0; UPDATED=0; SKIPPED=0; ERRORS=0

# ── Phase 1: Run importers for each agent ─────────────────────────────────────
while IFS= read -r agent_json; do
  agent_id="$(echo "$agent_json" | jq -r '.id')"
  agent_name="$(echo "$agent_json" | jq -r '.display_name')"
  enabled="$(echo "$agent_json" | jq -r '.enabled')"
  importer="$IMPORTERS_DIR/$(echo "$agent_json" | jq -r '.importer_script' | xargs basename)"

  [[ -n "$AGENT_FILTER" && "$agent_id" != "$AGENT_FILTER" ]] && continue
  if [[ "$enabled" == "false" && -z "$AGENT_FILTER" ]]; then
    log "Skipping disabled agent: $agent_id"; continue
  fi
  if [[ ! -f "$importer" ]]; then
    warn "No importer for $agent_id: $importer"; SKIPPED=$((SKIPPED+1)); continue
  fi

  log "Processing: $agent_name ($agent_id)"
  [[ "$DRY_RUN" == true ]] && { log "[dry-run] Would run: $importer"; continue; }

  set +e
  output="$(bash "$importer" \
    --agent-json "$agent_json" \
    --archive-dir "$ARCHIVE_DIR" \
    --since "${SINCE_DATE:-}" \
    --repo-root "$REPO_ROOT" \
    --force "$FORCE" \
    2>&1)"
  exit_code=$?
  set -e

  if [[ $exit_code -ne 0 ]]; then
    err "Importer failed ($agent_id): $output"; ERRORS=$((ERRORS+1))
  else
    echo "$output"
    # Count new vs updated from importer output
    new_count="$(echo "$output" | grep -c '\[new\]' || true)"
    upd_count="$(echo "$output" | grep -c '\[updated\]' || true)"
    NEW=$((NEW + new_count)); UPDATED=$((UPDATED + upd_count))
  fi
  echo ""
done < <(jq -c '.agents[]' "$CONFIG")

# ── Phase 2: Staleness check on existing archives ─────────────────────────────
if [[ "$NEW_ONLY" == false && "$DRY_RUN" == false ]]; then
  log "Checking for stale archives (sessions that grew since last harvest)..."
  STALE_COUNT=0

  while IFS= read -r meta_file; do
    [[ -f "$meta_file" ]] || continue
    agent_id="$(jq -r '.agent_id' "$meta_file" 2>/dev/null)"
    raw_path="$(jq -r '.raw_path' "$meta_file" 2>/dev/null)"
    session_id="$(jq -r '.session_id' "$meta_file" 2>/dev/null)"
    dest_dir="$(dirname "$meta_file")"

    [[ -n "$AGENT_FILTER" && "$agent_id" != "$AGENT_FILTER" ]] && continue
    [[ ! -f "$raw_path" ]] && continue  # raw gone

    if [[ "$FORCE" == true ]] || is_stale "$meta_file" "$raw_path"; then
      current_size="$(file_size_bytes "$raw_path")"
      stored_size="$(jq -r '.raw_size_bytes // 0' "$meta_file" 2>/dev/null)"
      current_lines="$(wc -l < "$raw_path" 2>/dev/null | tr -d ' ')"
      current_mtime="$(file_mtime "$raw_path")"
      harvest_count="$(jq -r '.harvest_count // 1' "$meta_file" 2>/dev/null)"
      new_count=$((harvest_count + 1))

      update "Stale: $agent_id/${session_id:0:8} (${stored_size}B → ${current_size}B, ${current_lines} lines)"

      # Find and re-run the appropriate importer for this agent
      agent_json="$(jq -c ".agents[] | select(.id == \"$agent_id\")" "$CONFIG" 2>/dev/null)"
      importer_rel="$(echo "$agent_json" | jq -r '.importer_script // ""' | xargs basename 2>/dev/null)"
      importer="$IMPORTERS_DIR/$importer_rel"

      if [[ -f "$importer" ]]; then
        set +e
        bash "$importer" \
          --agent-json "$agent_json" \
          --archive-dir "$ARCHIVE_DIR" \
          --since "" \
          --repo-root "$REPO_ROOT" \
          --force true \
          --target-session "$session_id" \
          2>&1 | grep -v "Already harvested"
        set -e
        UPDATED=$((UPDATED+1))
        STALE_COUNT=$((STALE_COUNT+1))
      else
        warn "No importer for stale $agent_id session"
      fi
    fi
  done < <(find "$ARCHIVE_DIR" -name "metadata.json" | sort 2>/dev/null)

  [[ $STALE_COUNT -eq 0 ]] && ok "No stale sessions found — all archives are current."
fi

# ── Phase 3: Cleanup warning for aging Claude Code sessions ───────────────────
log "Checking Claude Code session cleanup windows..."
while IFS= read -r meta_file; do
  agent_id="$(jq -r '.agent_id' "$meta_file" 2>/dev/null)"
  [[ "$agent_id" != "claude-code" ]] && continue
  raw_path="$(jq -r '.raw_path' "$meta_file" 2>/dev/null)"
  [[ ! -f "$raw_path" ]] && continue
  mtime="$(file_mtime "$raw_path")"
  age_days=$(( (NOW_UNIX - mtime) / 86400 ))
  days_remaining=$((30 - age_days))
  session_id="$(jq -r '.session_id' "$meta_file" 2>/dev/null | cut -c1-8)"
  if [[ $days_remaining -le 10 && $days_remaining -gt 0 ]]; then
    warn "Claude Code session $session_id — only $days_remaining days before auto-delete!"
    warn "  Preserve: cp '$raw_path' /path/to/permanent/archive/"
  elif [[ $days_remaining -le 0 ]]; then
    warn "Claude Code session $session_id — MAY ALREADY BE DELETED (age: ~$age_days days)"
  fi
done < <(find "$ARCHIVE_DIR" -name "metadata.json" 2>/dev/null)

# ── Phase 4: Regenerate index ──────────────────────────────────────────────────
if [[ "$DRY_RUN" == false && $(( NEW + UPDATED )) -gt 0 ]]; then
  log "Regenerating session index..."
  {
    echo "# Session Index"
    echo ""
    echo "_Auto-generated by \`tools/sessions/harvest-sessions.sh\`. Do not edit._"
    echo ""; echo "Last updated: $TODAY"; echo ""
    echo "| Date | Agent | Session ID | Harvested | Status | Summary |"
    echo "|------|-------|------------|-----------|--------|---------|"
    find "$ARCHIVE_DIR" -name "metadata.json" | sort -r | while read -r f; do
      agent="$(jq -r '.agent_id' "$f" 2>/dev/null)"
      date="$(jq -r '.date' "$f" 2>/dev/null)"
      sid="$(jq -r '.session_id' "$f" 2>/dev/null | cut -c1-8)"
      raw="$(jq -r '.raw_path' "$f" 2>/dev/null)"
      count="$(jq -r '.harvest_count // 1' "$f" 2>/dev/null)"
      status="$(session_status "$raw" "$agent" "")"
      summary="$(jq -r '.summary_one_line // "—"' "$f" 2>/dev/null | cut -c1-60)"
      rel="$(dirname "$f" | sed "s|$REPO_ROOT/||")"
      echo "| $date | $agent | \`$sid\` | ×$count | $status | [$summary]($rel/summary.md) |"
    done
  } > "$INDEX_FILE"
  ok "Index updated: $INDEX_FILE"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
printf " New sessions : %d\n" "$NEW"
printf " Updated      : %d\n" "$UPDATED"
printf " Skipped      : %d\n" "$SKIPPED"
printf " Errors       : %d\n" "$ERRORS"
echo "══════════════════════════════════════════"
[[ $ERRORS -gt 0 ]] && exit 1
exit 0
