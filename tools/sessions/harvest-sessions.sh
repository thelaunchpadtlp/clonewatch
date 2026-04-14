#!/usr/bin/env bash
# =============================================================================
# harvest-sessions.sh — CloneWatch Session Harvest Automation
# =============================================================================
# Discovers, imports, and summarizes agent sessions into the Sesiones
# Importantes subsystem. Designed to be future-proof: new agents are added
# by dropping an importer script in tools/sessions/importers/ and registering
# the agent in sessions-config.json.
#
# Usage:
#   ./harvest-sessions.sh                    # harvest all enabled agents
#   ./harvest-sessions.sh --agent claude-code  # specific agent only
#   ./harvest-sessions.sh --agent codex --since 2026-04-14
#   ./harvest-sessions.sh --list             # list known agents
#   ./harvest-sessions.sh --status           # show what's already harvested
#   ./harvest-sessions.sh --dry-run          # preview without writing
#
# Output:
#   docs/sessions/archive/YYYY-MM-DD/{agent}-{session-id}/
#     metadata.json       — structured session metadata
#     summary.md          — human-readable summary
#     raw-ref.txt         — path to original raw file (not copied by default)
#   docs/sessions/index.md  — updated automatically
#
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
ACTION="harvest"
TODAY="$(date -u +%Y-%m-%d)"

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log()  { echo -e "${BLUE}[harvest]${NC} $*"; }
ok()   { echo -e "${GREEN}[ok]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[error]${NC} $*" >&2; }

# ── Argument parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)    AGENT_FILTER="$2"; shift 2 ;;
    --since)    SINCE_DATE="$2"; shift 2 ;;
    --dry-run)  DRY_RUN=true; shift ;;
    --list)     ACTION="list"; shift ;;
    --status)   ACTION="status"; shift ;;
    --help|-h)  grep '^#' "$0" | sed 's/^# \{0,2\}//'; exit 0 ;;
    *) err "Unknown argument: $1"; exit 1 ;;
  esac
done

# ── Dependency check ─────────────────────────────────────────────────────────
for cmd in jq date; do
  if ! command -v "$cmd" &>/dev/null; then
    err "Required command not found: $cmd"
    err "Install with: brew install $cmd"
    exit 1
  fi
done

if [[ ! -f "$CONFIG" ]]; then
  err "Config not found: $CONFIG"
  exit 1
fi

# ── List action ──────────────────────────────────────────────────────────────
if [[ "$ACTION" == "list" ]]; then
  echo ""
  echo "Registered agents in sessions-config.json:"
  echo ""
  jq -r '.agents[] | "  \(.id) (\(.display_name)) — enabled=\(.enabled) | format=\(.format_id)"' "$CONFIG"
  echo ""
  exit 0
fi

# ── Status action ────────────────────────────────────────────────────────────
if [[ "$ACTION" == "status" ]]; then
  echo ""
  echo "Harvested sessions in $ARCHIVE_DIR:"
  echo ""
  if [[ -d "$ARCHIVE_DIR" ]]; then
    find "$ARCHIVE_DIR" -name "metadata.json" | sort | while read -r f; do
      dir="$(dirname "$f")"
      agent="$(jq -r '.agent_id' "$f" 2>/dev/null || echo "unknown")"
      date="$(jq -r '.date' "$f" 2>/dev/null || echo "unknown")"
      session_id="$(jq -r '.session_id' "$f" 2>/dev/null || echo "unknown")"
      echo "  [$date] $agent — $session_id"
    done
  else
    echo "  (no sessions harvested yet)"
  fi
  echo ""
  exit 0
fi

# ── Main harvest ─────────────────────────────────────────────────────────────
log "CloneWatch Session Harvest — $TODAY"
log "Config: $CONFIG"
log "Archive: $ARCHIVE_DIR"
[[ "$DRY_RUN" == true ]] && warn "DRY RUN — no files will be written"
echo ""

AGENTS_JSON="$(jq -c '.agents[]' "$CONFIG")"
HARVESTED=0
SKIPPED=0
ERRORS=0

while IFS= read -r agent_json; do
  agent_id="$(echo "$agent_json" | jq -r '.id')"
  agent_name="$(echo "$agent_json" | jq -r '.display_name')"
  enabled="$(echo "$agent_json" | jq -r '.enabled')"
  importer_rel="$(echo "$agent_json" | jq -r '.importer_script')"
  importer="$IMPORTERS_DIR/$(basename "$importer_rel")"

  # Filter by agent if specified
  if [[ -n "$AGENT_FILTER" && "$agent_id" != "$AGENT_FILTER" ]]; then
    continue
  fi

  # Skip disabled agents (unless explicitly targeted)
  if [[ "$enabled" == "false" && -z "$AGENT_FILTER" ]]; then
    log "Skipping disabled agent: $agent_id"
    SKIPPED=$((SKIPPED+1))
    continue
  fi

  log "Processing agent: $agent_name ($agent_id)"

  # Check importer script exists
  if [[ ! -f "$importer" ]]; then
    warn "Importer not found for $agent_id: $importer"
    warn "Create $importer to enable harvesting for this agent."
    SKIPPED=$((SKIPPED+1))
    continue
  fi

  # Run the importer
  if [[ "$DRY_RUN" == true ]]; then
    log "[dry-run] Would run: $importer --config '$agent_json' --archive '$ARCHIVE_DIR' --since '${SINCE_DATE:-all}'"
    continue
  fi

  set +e
  output="$(bash "$importer" \
    --agent-json "$agent_json" \
    --archive-dir "$ARCHIVE_DIR" \
    --since "${SINCE_DATE:-}" \
    --repo-root "$REPO_ROOT" \
    2>&1)"
  importer_exit=$?
  set -e

  if [[ $importer_exit -ne 0 ]]; then
    err "Importer failed for $agent_id (exit $importer_exit):"
    err "$output"
    ERRORS=$((ERRORS+1))
  else
    echo "$output"
    HARVESTED=$((HARVESTED+1))
  fi

  echo ""
done <<< "$AGENTS_JSON"

# ── Update index ──────────────────────────────────────────────────────────────
if [[ "$DRY_RUN" == false && "$HARVESTED" -gt 0 ]]; then
  log "Regenerating session index..."

  {
    echo "# Session Index"
    echo ""
    echo "_Auto-generated by \`tools/sessions/harvest-sessions.sh\`. Do not edit manually._"
    echo ""
    echo "Last updated: $TODAY"
    echo ""
    echo "| Date | Agent | Session ID | Summary |"
    echo "|------|-------|------------|---------|"

    find "$ARCHIVE_DIR" -name "metadata.json" | sort -r | while read -r f; do
      agent="$(jq -r '.agent_id' "$f" 2>/dev/null || echo "?")"
      date="$(jq -r '.date' "$f" 2>/dev/null || echo "?")"
      sid="$(jq -r '.session_id' "$f" 2>/dev/null || echo "?")"
      summary="$(jq -r '.summary_one_line // "—"' "$f" 2>/dev/null)"
      dir="$(dirname "$f")"
      rel_dir="${dir#$REPO_ROOT/}"
      echo "| $date | $agent | \`$sid\` | [$summary]($rel_dir/summary.md) |"
    done
  } > "$INDEX_FILE"

  ok "Index updated: $INDEX_FILE"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════"
echo " Harvest complete"
echo " Harvested : $HARVESTED agent(s)"
echo " Skipped   : $SKIPPED agent(s)"
echo " Errors    : $ERRORS agent(s)"
echo "═══════════════════════════════════════"

if [[ $ERRORS -gt 0 ]]; then
  exit 1
fi
