#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

OWNER=""
AGENT_APP=""
SESSION_ID=""
MODE="single-writer"
TTL_MINUTES=30
AUTO_CLAIM="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner) OWNER="$2"; shift 2 ;;
    --agent-app) AGENT_APP="$2"; shift 2 ;;
    --session-id) SESSION_ID="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --ttl-minutes) TTL_MINUTES="$2"; shift 2 ;;
    --no-claim) AUTO_CLAIM="false"; shift 1 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$OWNER" || -z "$AGENT_APP" || -z "$SESSION_ID" ]]; then
  echo "Usage: begin-session.sh --owner <name> --agent-app <app> --session-id <id> [--mode single-writer|direct-main|parallel-branches] [--ttl-minutes 30] [--no-claim]"
  exit 1
fi

ROOT="$(repo_root)"
ensure_collab_paths "$ROOT"

git -C "$ROOT" fetch origin --quiet || {
  append_event "$ROOT" "$OWNER" "$AGENT_APP" "$SESSION_ID" "SYNC_FETCH_FAILED" "error" "git fetch failed during BEGIN." "{}"
  echo "BEGIN failed: git fetch origin failed."
  exit 3
}

BASE_COMMIT="$(git -C "$ROOT" rev-parse HEAD)"
STATUS="$(git -C "$ROOT" status --porcelain | wc -l | tr -d ' ')"
DETAILS="{\"base_commit\":\"$(json_escape "$BASE_COMMIT")\",\"local_changes_count\":$STATUS,\"mode\":\"$(json_escape "$MODE")\"}"

append_event "$ROOT" "$OWNER" "$AGENT_APP" "$SESSION_ID" "BEGIN" "ok" "Session begin recorded." "$DETAILS"

if [[ "$AUTO_CLAIM" == "true" ]]; then
  "$SCRIPT_DIR/claim-lock.sh" \
    --owner "$OWNER" \
    --agent-app "$AGENT_APP" \
    --session-id "$SESSION_ID" \
    --mode "$MODE" \
    --ttl-minutes "$TTL_MINUTES" \
    --base-commit "$BASE_COMMIT"
fi

echo "BEGIN complete for $OWNER ($AGENT_APP / $SESSION_ID)."

