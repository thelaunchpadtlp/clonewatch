#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

OWNER=""
AGENT_APP=""
SESSION_ID=""
FORCE="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner) OWNER="$2"; shift 2 ;;
    --agent-app) AGENT_APP="$2"; shift 2 ;;
    --session-id) SESSION_ID="$2"; shift 2 ;;
    --force) FORCE="true"; shift 1 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$OWNER" || -z "$AGENT_APP" || -z "$SESSION_ID" ]]; then
  echo "Usage: release-lock.sh --owner <name> --agent-app <app> --session-id <id> [--force]"
  exit 1
fi

ROOT="$(repo_root)"
ensure_collab_paths "$ROOT"
LOCK_FILE="$(lock_file "$ROOT")"

if [[ ! -f "$LOCK_FILE" ]]; then
  append_event "$ROOT" "$OWNER" "$AGENT_APP" "$SESSION_ID" "RELEASE_LOCK_NOOP" "warn" "No lock file found during release." "{}"
  echo "No lock file found."
  exit 0
fi

LOCK_OWNER="$(read_lock_value "$LOCK_FILE" "owner")"
LOCK_SESSION="$(read_lock_value "$LOCK_FILE" "session_id")"

if [[ "$FORCE" != "true" && ( "$LOCK_OWNER" != "$OWNER" || "$LOCK_SESSION" != "$SESSION_ID" ) ]]; then
  append_event "$ROOT" "$OWNER" "$AGENT_APP" "$SESSION_ID" "RELEASE_LOCK_DENIED" "error" \
    "Refused lock release because ownership mismatch." \
    "{\"lock_owner\":\"$(json_escape "$LOCK_OWNER")\",\"lock_session_id\":\"$(json_escape "$LOCK_SESSION")\"}"
  echo "Lock release denied: owner/session mismatch."
  exit 4
fi

rm -f "$LOCK_FILE"
append_event "$ROOT" "$OWNER" "$AGENT_APP" "$SESSION_ID" "RELEASE_LOCK" "ok" "Writer lock released." "{}"

sqlite3 "$(collab_db_file "$ROOT")" \
  "INSERT INTO lock_history (timestamp_utc, owner, session_id, action, lock_file, notes)
   VALUES ('$(now_iso)','$(sql_escape "$OWNER")','$(sql_escape "$SESSION_ID")','release','$(sql_escape "$LOCK_FILE")','force=$(sql_escape "$FORCE")');"

echo "Lock released."

