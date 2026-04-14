#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

TASK_ID=""
EVENT=""
OWNER=""
AGENT_APP=""
SESSION_ID=""
MESSAGE=""
STATUS="ok"
ARTIFACTS_CSV=""
QUESTIONS_CSV=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task-id) TASK_ID="$2"; shift 2 ;;
    --event) EVENT="$2"; shift 2 ;;
    --owner) OWNER="$2"; shift 2 ;;
    --agent-app) AGENT_APP="$2"; shift 2 ;;
    --session-id) SESSION_ID="$2"; shift 2 ;;
    --message) MESSAGE="$2"; shift 2 ;;
    --status) STATUS="$2"; shift 2 ;;
    --artifacts-csv) ARTIFACTS_CSV="$2"; shift 2 ;;
    --questions-csv) QUESTIONS_CSV="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$TASK_ID" || -z "$EVENT" || -z "$OWNER" || -z "$AGENT_APP" || -z "$SESSION_ID" || -z "$MESSAGE" ]]; then
  echo "Usage: external-update-task.sh --task-id <id> --event <BLOCKED|DONE|REJECTED|INFO> --owner <name> --agent-app <app> --session-id <id> --message <text> [--status ok|warn|error] [--artifacts-csv a,b] [--questions-csv q1,q2]"
  exit 1
fi

case "$EVENT" in
  BLOCKED|DONE|REJECTED|INFO) ;;
  *) echo "Invalid event: $EVENT"; exit 2 ;;
esac

csv_to_json_array() {
  local input="$1"
  if [[ -z "$input" ]]; then
    printf '[]'
    return
  fi
  local first="true"
  local out="["
  IFS=',' read -r -a parts <<< "$input"
  for raw in "${parts[@]}"; do
    local item
    item="$(printf '%s' "$raw" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [[ -z "$item" ]] && continue
    if [[ "$first" == "false" ]]; then
      out+=","
    fi
    out+="\"$(json_escape "$item")\""
    first="false"
  done
  out+="]"
  printf '%s' "$out"
}

ROOT="$(repo_root)"
ensure_collab_paths "$ROOT"
ensure_collab_db "$ROOT"

TASK_FILE="$(external_inbox_dir "$ROOT")/$TASK_ID.json"
if [[ ! -f "$TASK_FILE" ]]; then
  echo "Task not found: ${TASK_FILE#$ROOT/}"
  exit 3
fi

TS="$(now_iso)"
ARTIFACTS_JSON="$(csv_to_json_array "$ARTIFACTS_CSV")"
QUESTIONS_JSON="$(csv_to_json_array "$QUESTIONS_CSV")"
OUTBOX_PATH="$(external_outbox_dir "$ROOT")/${TASK_ID}--$(date -u +%Y%m%d-%H%M%S)--${EVENT}.json"

cat > "$OUTBOX_PATH" <<JSON
{
  "task_id": "$(json_escape "$TASK_ID")",
  "timestamp": "$TS",
  "event": "$EVENT",
  "status": "$(json_escape "$STATUS")",
  "owner": "$(json_escape "$OWNER")",
  "agent_app": "$(json_escape "$AGENT_APP")",
  "session_id": "$(json_escape "$SESSION_ID")",
  "message": "$(json_escape "$MESSAGE")",
  "artifacts": $ARTIFACTS_JSON,
  "questions": $QUESTIONS_JSON
}
JSON

append_event "$ROOT" "$OWNER" "$AGENT_APP" "$SESSION_ID" "EXTERNAL_TASK_${EVENT}" "$STATUS" \
  "$MESSAGE" \
  "{\"task_id\":\"$(json_escape "$TASK_ID")\",\"outbox_path\":\"$(json_escape "${OUTBOX_PATH#$ROOT/}")\"}"

NEXT_STATUS="$EVENT"
if [[ "$EVENT" == "INFO" ]]; then
  NEXT_STATUS="CLAIMED"
fi

sqlite3 "$(collab_db_file "$ROOT")" <<SQL
UPDATE external_tasks
SET status='$(sql_escape "$NEXT_STATUS")',
    owner='$(sql_escape "$OWNER")',
    latest_message='$(sql_escape "$MESSAGE")',
    updated_at_utc='$(sql_escape "$TS")'
WHERE task_id='$(sql_escape "$TASK_ID")';

INSERT INTO external_task_events (
  task_id, timestamp_utc, event, status, owner, agent_app, session_id, message, outbox_path
) VALUES (
  '$(sql_escape "$TASK_ID")',
  '$(sql_escape "$TS")',
  '$(sql_escape "$EVENT")',
  '$(sql_escape "$STATUS")',
  '$(sql_escape "$OWNER")',
  '$(sql_escape "$AGENT_APP")',
  '$(sql_escape "$SESSION_ID")',
  '$(sql_escape "$MESSAGE")',
  '$(sql_escape "${OUTBOX_PATH#$ROOT/}")'
);
SQL

echo "Task updated: $TASK_ID ($EVENT)"
