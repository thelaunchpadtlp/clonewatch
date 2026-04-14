#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

TASK_ID=""
OWNER=""
AGENT_APP=""
SESSION_ID=""
MESSAGE="Task claimed and queued for execution."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task-id) TASK_ID="$2"; shift 2 ;;
    --owner) OWNER="$2"; shift 2 ;;
    --agent-app) AGENT_APP="$2"; shift 2 ;;
    --session-id) SESSION_ID="$2"; shift 2 ;;
    --message) MESSAGE="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$TASK_ID" || -z "$OWNER" || -z "$AGENT_APP" || -z "$SESSION_ID" ]]; then
  echo "Usage: external-claim-task.sh --task-id <id> --owner <name> --agent-app <app> --session-id <id> [--message <text>]"
  exit 1
fi

ROOT="$(repo_root)"
ensure_collab_paths "$ROOT"
ensure_collab_db "$ROOT"

TASK_FILE="$(external_inbox_dir "$ROOT")/$TASK_ID.json"
if [[ ! -f "$TASK_FILE" ]]; then
  echo "Task not found: ${TASK_FILE#$ROOT/}"
  exit 2
fi

LOCK_FILE="$(lock_file "$ROOT")"
if [[ ! -f "$LOCK_FILE" ]]; then
  echo "Cannot claim task without active lock."
  exit 3
fi

LOCK_OWNER="$(read_lock_value "$LOCK_FILE" "owner")"
LOCK_SESSION="$(read_lock_value "$LOCK_FILE" "session_id")"
if [[ "$LOCK_OWNER" != "$OWNER" || "$LOCK_SESSION" != "$SESSION_ID" ]]; then
  echo "Lock ownership mismatch. Required owner/session: $OWNER / $SESSION_ID"
  exit 4
fi

TS="$(now_iso)"
OUTBOX_PATH="$(external_outbox_dir "$ROOT")/${TASK_ID}--$(date -u +%Y%m%d-%H%M%S)--CLAIMED.json"
cat > "$OUTBOX_PATH" <<JSON
{
  "task_id": "$(json_escape "$TASK_ID")",
  "timestamp": "$TS",
  "event": "CLAIMED",
  "status": "ok",
  "owner": "$(json_escape "$OWNER")",
  "agent_app": "$(json_escape "$AGENT_APP")",
  "session_id": "$(json_escape "$SESSION_ID")",
  "message": "$(json_escape "$MESSAGE")",
  "artifacts": [],
  "questions": []
}
JSON

append_event "$ROOT" "$OWNER" "$AGENT_APP" "$SESSION_ID" "EXTERNAL_TASK_CLAIMED" "ok" \
  "External task claimed." \
  "{\"task_id\":\"$(json_escape "$TASK_ID")\",\"outbox_path\":\"$(json_escape "${OUTBOX_PATH#$ROOT/}")\"}"

sqlite3 "$(collab_db_file "$ROOT")" <<SQL
UPDATE external_tasks
SET status='CLAIMED',
    owner='$(sql_escape "$OWNER")',
    latest_message='$(sql_escape "$MESSAGE")',
    updated_at_utc='$(sql_escape "$TS")'
WHERE task_id='$(sql_escape "$TASK_ID")';

INSERT INTO external_task_events (
  task_id, timestamp_utc, event, status, owner, agent_app, session_id, message, outbox_path
) VALUES (
  '$(sql_escape "$TASK_ID")',
  '$(sql_escape "$TS")',
  'CLAIMED',
  'ok',
  '$(sql_escape "$OWNER")',
  '$(sql_escape "$AGENT_APP")',
  '$(sql_escape "$SESSION_ID")',
  '$(sql_escape "$MESSAGE")',
  '$(sql_escape "${OUTBOX_PATH#$ROOT/}")'
);
SQL

echo "Task claimed: $TASK_ID"
