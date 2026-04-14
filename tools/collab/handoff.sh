#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

OWNER=""
AGENT_APP=""
SESSION_ID=""
MODE="single-writer"
SUMMARY=""
PENDING=""
RISKS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner) OWNER="$2"; shift 2 ;;
    --agent-app) AGENT_APP="$2"; shift 2 ;;
    --session-id) SESSION_ID="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --summary) SUMMARY="$2"; shift 2 ;;
    --pending) PENDING="$2"; shift 2 ;;
    --risks) RISKS="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$OWNER" || -z "$AGENT_APP" || -z "$SESSION_ID" || -z "$SUMMARY" ]]; then
  echo "Usage: handoff.sh --owner <name> --agent-app <app> --session-id <id> --summary <text> [--mode single-writer|direct-main|parallel-branches] [--pending <text>] [--risks <text>]"
  exit 1
fi

ROOT="$(repo_root)"
ensure_collab_paths "$ROOT"

TS="$(date -u +"%Y%m%d-%H%M%S")"
SAFE_OWNER="$(printf '%s' "$OWNER" | tr ' ' '-' | tr -cd '[:alnum:]-_')"
HANDOFF_PATH="$ROOT/docs/collab/handoffs/${TS}-${SAFE_OWNER}.md"
BASE_COMMIT="$(git -C "$ROOT" merge-base HEAD origin/main 2>/dev/null || git -C "$ROOT" rev-parse HEAD)"
END_COMMIT="$(git -C "$ROOT" rev-parse HEAD)"

cat > "$HANDOFF_PATH" <<MD
# Handoff

- Timestamp (UTC): $(now_iso)
- Owner: $OWNER
- Agent app: $AGENT_APP
- Session id: $SESSION_ID
- Mode: $MODE
- Base commit: $BASE_COMMIT
- End commit: $END_COMMIT

## What was done

- $SUMMARY

## What is pending

- ${PENDING:-None declared}

## Risks / warnings

- ${RISKS:-None declared}

## Next recommended command sequence

\`\`\`bash
git status -sb
git fetch origin
swift test
\`\`\`
MD

append_event "$ROOT" "$OWNER" "$AGENT_APP" "$SESSION_ID" "HANDOFF" "ok" \
  "Structured handoff written." \
  "{\"handoff_path\":\"$(json_escape "${HANDOFF_PATH#$ROOT/}")\",\"mode\":\"$(json_escape "$MODE")\"}"

sqlite3 "$(collab_db_file "$ROOT")" \
  "INSERT INTO handoffs (timestamp_utc, owner, agent_app, session_id, handoff_path, summary)
   VALUES ('$(now_iso)','$(sql_escape "$OWNER")','$(sql_escape "$AGENT_APP")','$(sql_escape "$SESSION_ID")','$(sql_escape "${HANDOFF_PATH#$ROOT/}")','$(sql_escape "$SUMMARY")');"

echo "Handoff written to ${HANDOFF_PATH#$ROOT/}"

