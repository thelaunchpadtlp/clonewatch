#!/usr/bin/env bash
set -euo pipefail

repo_root() {
  git rev-parse --show-toplevel
}

now_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

now_epoch() {
  date -u +%s
}

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

sql_escape() {
  printf '%s' "$1" | sed "s/'/''/g"
}

ensure_collab_paths() {
  local root="$1"
  mkdir -p \
    "$root/.clonewatch" \
    "$root/docs/collab/handoffs" \
    "$root/docs/collab/external-inbox" \
    "$root/docs/collab/external-outbox" \
    "$root/tools/collab"
}

lock_file() {
  local root="$1"
  printf '%s/.clonewatch/agent-lock.json' "$root"
}

session_log_file() {
  local root="$1"
  printf '%s/docs/collab/session-log.jsonl' "$root"
}

collab_db_file() {
  local root="$1"
  printf '%s/docs/collab/collab.sqlite' "$root"
}

collab_schema_file() {
  local root="$1"
  printf '%s/docs/collab/schema.sql' "$root"
}

external_inbox_dir() {
  local root="$1"
  printf '%s/docs/collab/external-inbox' "$root"
}

external_outbox_dir() {
  local root="$1"
  printf '%s/docs/collab/external-outbox' "$root"
}

ensure_collab_db() {
  local root="$1"
  local db
  local schema
  db="$(collab_db_file "$root")"
  schema="$(collab_schema_file "$root")"
  if [[ ! -f "$db" ]]; then
    sqlite3 "$db" < "$schema"
  fi
}

append_event() {
  local root="$1"
  local owner="$2"
  local agent_app="$3"
  local session_id="$4"
  local event="$5"
  local status="$6"
  local message="$7"
  local details_json="${8:-{}}"

  local ts
  ts="$(now_iso)"

  local log_file
  log_file="$(session_log_file "$root")"

  ensure_collab_db "$root"

  printf '{"timestamp":"%s","owner":"%s","agent_app":"%s","session_id":"%s","event":"%s","status":"%s","message":"%s","details":%s}\n' \
    "$ts" \
    "$(json_escape "$owner")" \
    "$(json_escape "$agent_app")" \
    "$(json_escape "$session_id")" \
    "$(json_escape "$event")" \
    "$(json_escape "$status")" \
    "$(json_escape "$message")" \
    "$details_json" >> "$log_file"

  sqlite3 "$(collab_db_file "$root")" \
    "INSERT INTO session_events (timestamp_utc, owner, agent_app, session_id, event, status, message, details_json)
     VALUES ('$(sql_escape "$ts")','$(sql_escape "$owner")','$(sql_escape "$agent_app")','$(sql_escape "$session_id")','$(sql_escape "$event")','$(sql_escape "$status")','$(sql_escape "$message")','$(sql_escape "$details_json")');"
}

read_lock_value() {
  local file="$1"
  local key="$2"
  grep -E "\"$key\"[[:space:]]*:" "$file" | head -n1 | sed -E 's/^[^:]+:[[:space:]]*"?([^",}]+)"?,?$/\1/'
}
