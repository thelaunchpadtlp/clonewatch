#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

OWNER=""
AGENT_APP=""
SESSION_ID=""
MODE="single-writer"
TTL_MINUTES=30
BASE_COMMIT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner) OWNER="$2"; shift 2 ;;
    --agent-app) AGENT_APP="$2"; shift 2 ;;
    --session-id) SESSION_ID="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --ttl-minutes) TTL_MINUTES="$2"; shift 2 ;;
    --base-commit) BASE_COMMIT="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$OWNER" || -z "$AGENT_APP" || -z "$SESSION_ID" ]]; then
  echo "Usage: claim-lock.sh --owner <name> --agent-app <app> --session-id <id> [--mode single-writer|direct-main|parallel-branches] [--ttl-minutes 30] [--base-commit <sha>]"
  exit 1
fi

ROOT="$(repo_root)"
ensure_collab_paths "$ROOT"
LOCK_FILE="$(lock_file "$ROOT")"
NOW_EPOCH="$(now_epoch)"
STARTED_AT="$(now_iso)"
EXPIRES_EPOCH="$((NOW_EPOCH + TTL_MINUTES * 60))"
EXPIRES_AT="$(date -u -r "$EXPIRES_EPOCH" +"%Y-%m-%dT%H:%M:%SZ")"

if [[ -z "$BASE_COMMIT" ]]; then
  BASE_COMMIT="$(git -C "$ROOT" rev-parse HEAD)"
fi

if [[ -f "$LOCK_FILE" ]]; then
  CURRENT_OWNER="$(read_lock_value "$LOCK_FILE" "owner")"
  CURRENT_SESSION="$(read_lock_value "$LOCK_FILE" "session_id")"
  CURRENT_EXPIRES="$(read_lock_value "$LOCK_FILE" "lease_expires_at_epoch")"
  if [[ -n "$CURRENT_EXPIRES" && "$NOW_EPOCH" -le "$CURRENT_EXPIRES" ]]; then
    append_event "$ROOT" "$OWNER" "$AGENT_APP" "$SESSION_ID" "CLAIM_LOCK_DENIED" "error" \
      "Lock is active and owned by another session." \
      "{\"current_owner\":\"$(json_escape "$CURRENT_OWNER")\",\"current_session_id\":\"$(json_escape "$CURRENT_SESSION")\"}"
    echo "Lock denied: active lock is owned by $CURRENT_OWNER ($CURRENT_SESSION) until epoch $CURRENT_EXPIRES."
    exit 2
  fi

  append_event "$ROOT" "$OWNER" "$AGENT_APP" "$SESSION_ID" "RECOVERY_STALE_LOCK" "warn" \
    "Detected stale lock. Proceeding with safe reclaim." \
    "{\"previous_owner\":\"$(json_escape "$CURRENT_OWNER")\",\"previous_session_id\":\"$(json_escape "$CURRENT_SESSION")\"}"
fi

cat > "$LOCK_FILE" <<JSON
{
  "owner": "$(json_escape "$OWNER")",
  "agent_app": "$(json_escape "$AGENT_APP")",
  "session_id": "$(json_escape "$SESSION_ID")",
  "started_at": "$STARTED_AT",
  "lease_expires_at": "$EXPIRES_AT",
  "lease_expires_at_epoch": $EXPIRES_EPOCH,
  "base_commit": "$BASE_COMMIT",
  "mode": "$MODE",
  "repo": "CloneWatch"
}
JSON

append_event "$ROOT" "$OWNER" "$AGENT_APP" "$SESSION_ID" "CLAIM_LOCK" "ok" \
  "Writer lock acquired." \
  "{\"mode\":\"$(json_escape "$MODE")\",\"base_commit\":\"$(json_escape "$BASE_COMMIT")\",\"lease_expires_at\":\"$EXPIRES_AT\"}"

sqlite3 "$(collab_db_file "$ROOT")" \
  "INSERT INTO lock_history (timestamp_utc, owner, session_id, action, lock_file, notes)
   VALUES ('$(now_iso)','$(sql_escape "$OWNER")','$(sql_escape "$SESSION_ID")','claim','$(sql_escape "$LOCK_FILE")','mode=$(sql_escape "$MODE")');"

echo "Lock acquired by $OWNER ($SESSION_ID) in mode $MODE."

