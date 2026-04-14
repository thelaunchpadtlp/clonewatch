#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

FROM_APP=""
REQUESTER=""
TITLE=""
OBJECTIVE=""
TARGET_PATHS_CSV=""
CRITERIA_CSV=""
PRIORITY="normal"
URGENCY="soon"
TASK_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from-app) FROM_APP="$2"; shift 2 ;;
    --requester) REQUESTER="$2"; shift 2 ;;
    --title) TITLE="$2"; shift 2 ;;
    --objective) OBJECTIVE="$2"; shift 2 ;;
    --target-paths-csv) TARGET_PATHS_CSV="$2"; shift 2 ;;
    --criteria-csv) CRITERIA_CSV="$2"; shift 2 ;;
    --priority) PRIORITY="$2"; shift 2 ;;
    --urgency) URGENCY="$2"; shift 2 ;;
    --task-id) TASK_ID="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$FROM_APP" || -z "$REQUESTER" || -z "$TITLE" || -z "$OBJECTIVE" ]]; then
  echo "Usage: external-new-task.sh --from-app <app> --requester <name> --title <text> --objective <text> [--target-paths-csv a,b] [--criteria-csv c,d] [--priority low|normal|high] [--urgency later|soon|now] [--task-id EXT-...]"
  exit 1
fi

if [[ -z "$TASK_ID" ]]; then
  TASK_ID="EXT-$(date -u +%Y%m%d-%H%M%S)"
fi

case "$PRIORITY" in
  low|normal|high) ;;
  *) echo "Invalid priority: $PRIORITY"; exit 1 ;;
esac

case "$URGENCY" in
  later|soon|now) ;;
  *) echo "Invalid urgency: $URGENCY"; exit 1 ;;
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

INBOX_DIR="$(external_inbox_dir "$ROOT")"
OUTBOX_DIR="$(external_outbox_dir "$ROOT")"
TASK_FILE="$INBOX_DIR/$TASK_ID.json"

if [[ -f "$TASK_FILE" ]]; then
  echo "Task already exists: ${TASK_FILE#$ROOT/}"
  exit 2
fi

TS="$(now_iso)"
TARGET_PATHS_JSON="$(csv_to_json_array "$TARGET_PATHS_CSV")"
CRITERIA_JSON="$(csv_to_json_array "$CRITERIA_CSV")"

cat > "$TASK_FILE" <<JSON
{
  "task_id": "$(json_escape "$TASK_ID")",
  "created_at": "$TS",
  "from_external_app": "$(json_escape "$FROM_APP")",
  "requester": "$(json_escape "$REQUESTER")",
  "title": "$(json_escape "$TITLE")",
  "objective": "$(json_escape "$OBJECTIVE")",
  "target_paths": $TARGET_PATHS_JSON,
  "acceptance_criteria": $CRITERIA_JSON,
  "priority": "$PRIORITY",
  "urgency": "$URGENCY",
  "status": "NEW",
  "owner": "unassigned"
}
JSON

OUTBOX_PATH="$OUTBOX_DIR/${TASK_ID}--$(date -u +%Y%m%d-%H%M%S)--NEW.json"
cat > "$OUTBOX_PATH" <<JSON
{
  "task_id": "$(json_escape "$TASK_ID")",
  "timestamp": "$TS",
  "event": "NEW",
  "status": "ok",
  "owner": "external-requester",
  "agent_app": "$(json_escape "$FROM_APP")",
  "session_id": "external-$(json_escape "$TASK_ID")",
  "message": "External task created and queued in inbox.",
  "artifacts": [
    "$(json_escape "${TASK_FILE#$ROOT/}")"
  ],
  "questions": []
}
JSON

append_event "$ROOT" "external-requester" "$FROM_APP" "external-$TASK_ID" "EXTERNAL_TASK_NEW" "ok" \
  "External task queued in inbox." \
  "{\"task_id\":\"$(json_escape "$TASK_ID")\",\"inbox_path\":\"$(json_escape "${TASK_FILE#$ROOT/}")\"}"

sqlite3 "$(collab_db_file "$ROOT")" <<SQL
INSERT OR REPLACE INTO external_tasks (
  task_id, created_at_utc, from_external_app, requester, title, objective,
  priority, urgency, status, owner, inbox_path, latest_message, updated_at_utc
) VALUES (
  '$(sql_escape "$TASK_ID")',
  '$(sql_escape "$TS")',
  '$(sql_escape "$FROM_APP")',
  '$(sql_escape "$REQUESTER")',
  '$(sql_escape "$TITLE")',
  '$(sql_escape "$OBJECTIVE")',
  '$(sql_escape "$PRIORITY")',
  '$(sql_escape "$URGENCY")',
  'NEW',
  'unassigned',
  '$(sql_escape "${TASK_FILE#$ROOT/}")',
  'Task queued.',
  '$(sql_escape "$TS")'
);

INSERT INTO external_task_events (
  task_id, timestamp_utc, event, status, owner, agent_app, session_id, message, outbox_path
) VALUES (
  '$(sql_escape "$TASK_ID")',
  '$(sql_escape "$TS")',
  'NEW',
  'ok',
  'external-requester',
  '$(sql_escape "$FROM_APP")',
  'external-$(sql_escape "$TASK_ID")',
  'External task created.',
  '$(sql_escape "${OUTBOX_PATH#$ROOT/}")'
);
SQL

echo "External task queued: $TASK_ID"
echo "Inbox file: ${TASK_FILE#$ROOT/}"
