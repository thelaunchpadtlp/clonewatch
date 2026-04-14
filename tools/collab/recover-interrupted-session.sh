#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

OWNER=""
AGENT_APP=""
SESSION_ID=""
MODE="single-writer"
TTL_MINUTES=30
CLAIM_AFTER_RECOVERY="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner) OWNER="$2"; shift 2 ;;
    --agent-app) AGENT_APP="$2"; shift 2 ;;
    --session-id) SESSION_ID="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --ttl-minutes) TTL_MINUTES="$2"; shift 2 ;;
    --no-claim) CLAIM_AFTER_RECOVERY="false"; shift 1 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$OWNER" || -z "$AGENT_APP" || -z "$SESSION_ID" ]]; then
  echo "Usage: recover-interrupted-session.sh --owner <name> --agent-app <app> --session-id <id> [--mode single-writer|direct-main|parallel-branches] [--ttl-minutes 30] [--no-claim]"
  exit 1
fi

ROOT="$(repo_root)"
ensure_collab_paths "$ROOT"
LOCK_FILE="$(lock_file "$ROOT")"
NOW_EPOCH="$(now_epoch)"

append_event "$ROOT" "$OWNER" "$AGENT_APP" "$SESSION_ID" "RECOVERY_START" "warn" \
  "Recovery flow started after interrupted session." "{}"

if [[ ! -f "$LOCK_FILE" ]]; then
  append_event "$ROOT" "$OWNER" "$AGENT_APP" "$SESSION_ID" "RECOVERY_NO_LOCK" "ok" "No active lock found; normal resume allowed." "{}"
  echo "No lock present. Resume is clear."
  exit 0
fi

LOCK_OWNER="$(read_lock_value "$LOCK_FILE" "owner")"
LOCK_SESSION="$(read_lock_value "$LOCK_FILE" "session_id")"
LOCK_EXPIRES="$(read_lock_value "$LOCK_FILE" "lease_expires_at_epoch")"

if [[ -n "$LOCK_EXPIRES" && "$NOW_EPOCH" -le "$LOCK_EXPIRES" ]]; then
  append_event "$ROOT" "$OWNER" "$AGENT_APP" "$SESSION_ID" "RECOVERY_BLOCKED_ACTIVE_LOCK" "error" \
    "Recovery blocked because lock is still active." \
    "{\"lock_owner\":\"$(json_escape "$LOCK_OWNER")\",\"lock_session_id\":\"$(json_escape "$LOCK_SESSION")\",\"lease_expires_at_epoch\":$LOCK_EXPIRES}"
  echo "Recovery blocked: lock still active for $LOCK_OWNER ($LOCK_SESSION)."
  exit 5
fi

append_event "$ROOT" "$OWNER" "$AGENT_APP" "$SESSION_ID" "RECOVERY_STALE_LOCK_CONFIRMED" "warn" \
  "Stale lock confirmed; safe reclaim path enabled." \
  "{\"previous_owner\":\"$(json_escape "$LOCK_OWNER")\",\"previous_session_id\":\"$(json_escape "$LOCK_SESSION")\"}"

if [[ "$CLAIM_AFTER_RECOVERY" == "true" ]]; then
  "$SCRIPT_DIR/claim-lock.sh" \
    --owner "$OWNER" \
    --agent-app "$AGENT_APP" \
    --session-id "$SESSION_ID" \
    --mode "$MODE" \
    --ttl-minutes "$TTL_MINUTES"
fi

append_event "$ROOT" "$OWNER" "$AGENT_APP" "$SESSION_ID" "RECOVERY_COMPLETE" "ok" \
  "Recovery flow complete." \
  "{\"claim_after_recovery\":\"$CLAIM_AFTER_RECOVERY\"}"

echo "Recovery complete."

