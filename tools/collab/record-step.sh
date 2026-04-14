#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

OWNER=""
AGENT_APP=""
SESSION_ID=""
EVENT=""
STATUS="ok"
MESSAGE=""
DETAILS="{}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner) OWNER="$2"; shift 2 ;;
    --agent-app) AGENT_APP="$2"; shift 2 ;;
    --session-id) SESSION_ID="$2"; shift 2 ;;
    --event) EVENT="$2"; shift 2 ;;
    --status) STATUS="$2"; shift 2 ;;
    --message) MESSAGE="$2"; shift 2 ;;
    --details-json) DETAILS="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$OWNER" || -z "$AGENT_APP" || -z "$SESSION_ID" || -z "$EVENT" || -z "$MESSAGE" ]]; then
  echo "Usage: record-step.sh --owner <name> --agent-app <app> --session-id <id> --event <event> --message <text> [--status ok|warn|error] [--details-json '{}']"
  exit 1
fi

ROOT="$(repo_root)"
ensure_collab_paths "$ROOT"
append_event "$ROOT" "$OWNER" "$AGENT_APP" "$SESSION_ID" "$EVENT" "$STATUS" "$MESSAGE" "$DETAILS"
echo "Recorded event: $EVENT ($STATUS)"

