#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR/../.." rev-parse --show-toplevel)"
OWNER="collab-selftest"
AGENT_APP="clonewatch-selftest"
SESSION_ID="selftest-$(date -u +%s)"

cd "$ROOT"

"$SCRIPT_DIR/begin-session.sh" \
  --owner "$OWNER" \
  --agent-app "$AGENT_APP" \
  --session-id "$SESSION_ID" \
  --mode "single-writer" \
  --ttl-minutes 1

"$SCRIPT_DIR/record-step.sh" \
  --owner "$OWNER" \
  --agent-app "$AGENT_APP" \
  --session-id "$SESSION_ID" \
  --event "SELFTEST_VALIDATE" \
  --status "ok" \
  --message "Collab self-test event written."

"$SCRIPT_DIR/handoff.sh" \
  --owner "$OWNER" \
  --agent-app "$AGENT_APP" \
  --session-id "$SESSION_ID" \
  --mode "single-writer" \
  --summary "Collab self-test completed."

"$SCRIPT_DIR/release-lock.sh" \
  --owner "$OWNER" \
  --agent-app "$AGENT_APP" \
  --session-id "$SESSION_ID"

"$SCRIPT_DIR/update-sqlite.sh"

echo "Collab self-test passed."

