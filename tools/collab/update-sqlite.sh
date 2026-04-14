#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

ROOT="$(repo_root)"
ensure_collab_paths "$ROOT"
ensure_collab_db "$ROOT"

DB="$(collab_db_file "$ROOT")"
LOG="$(session_log_file "$ROOT")"

if [[ ! -f "$LOG" ]]; then
  echo "No session log found at $LOG"
  exit 0
fi

TMP_TABLE_SQL="
CREATE TABLE IF NOT EXISTS raw_session_log (
  line_hash TEXT PRIMARY KEY,
  raw_json TEXT NOT NULL,
  inserted_at_utc TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);
"
sqlite3 "$DB" "$TMP_TABLE_SQL"
sqlite3 "$DB" "PRAGMA busy_timeout=5000;"

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  hash="$(printf '%s' "$line" | shasum -a 256 | awk '{print $1}')"
  escaped="$(sql_escape "$line")"
  sqlite3 "$DB" "INSERT OR IGNORE INTO raw_session_log (line_hash, raw_json) VALUES ('$hash', '$escaped');"
done < "$LOG"

echo "SQLite updated from session-log.jsonl"
