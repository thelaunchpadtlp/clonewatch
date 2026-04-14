#!/bin/bash
# claude-checkpoint.sh — Automation trigger for Claude Code sessions
#
# Claude calls this script at key moments so that memory, docs, and records
# are always up-to-date without relying on manual memory.
#
# Usage:
#   ./tools/collab/claude-checkpoint.sh \
#     --trigger <type> \
#     --session-id <id> \
#     [--message "description"] \
#     [--agent-app "Claude Code"] \
#     [--owner "The Launch Pad - TLP"]
#
# Trigger types:
#   SESSION_START    — Run at start of every session (read context)
#   PLAN_APPROVED    — After user approves an implementation plan
#   TODO_DONE        — After completing a significant todo item
#   FINDING          — After an important discovery (research, inspection, etc.)
#   PROBLEM_DETECTED — After identifying a significant blocker or issue
#   SESSION_END      — At session close (mandatory close checklist)

set -euo pipefail

REPO_ROOT="/Users/Shared/Pruebas/CloneWatch"
TRIGGER=""
SESSION_ID=""
MESSAGE=""
AGENT_APP="Claude Code"
OWNER="The Launch Pad - TLP"

# ── Parse arguments ──────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --trigger)    TRIGGER="$2";     shift 2;;
    --session-id) SESSION_ID="$2";  shift 2;;
    --message)    MESSAGE="$2";     shift 2;;
    --agent-app)  AGENT_APP="$2";   shift 2;;
    --owner)      OWNER="$2";       shift 2;;
    *)
      echo "❌ Unknown argument: $1"
      echo "Usage: $0 --trigger <type> --session-id <id> [--message <msg>]"
      exit 1
      ;;
  esac
done

if [[ -z "$TRIGGER" ]]; then
  echo "❌ Error: --trigger is required"
  echo "Valid triggers: SESSION_START  PLAN_APPROVED  TODO_DONE  FINDING  PROBLEM_DETECTED  SESSION_END"
  exit 1
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DATE_SHORT=$(date +"%Y%m%d-%H%M%S")

echo "════════════════════════════════════════════════════"
echo "  CHECKPOINT: $TRIGGER"
echo "  Session:    ${SESSION_ID:-<none>}"
echo "  Time:       $TIMESTAMP"
[[ -n "$MESSAGE" ]] && echo "  Message:    $MESSAGE"
echo "════════════════════════════════════════════════════"

# ── Log to session record (non-fatal if no session) ──────────────────────────

if [[ -n "$SESSION_ID" ]] && [[ -x "$REPO_ROOT/tools/collab/record-step.sh" ]]; then
  "$REPO_ROOT/tools/collab/record-step.sh" \
    --owner "$OWNER" \
    --agent-app "$AGENT_APP" \
    --session-id "$SESSION_ID" \
    --event "CHECKPOINT_$TRIGGER" \
    --message "${MESSAGE:-Checkpoint: $TRIGGER at $TIMESTAMP}" 2>/dev/null || true
fi

# ── Trigger handlers ─────────────────────────────────────────────────────────

case "$TRIGGER" in

  # ── SESSION_START ────────────────────────────────────────────────────────
  SESSION_START)
    echo ""
    echo "▶ Reading current project state..."
    echo ""
    echo "═══ CURRENT STATE ═══════════════════════════════"
    cat "$REPO_ROOT/docs/collab/current-state.md" 2>/dev/null || echo "(file not found)"

    echo ""
    echo "═══ LATEST HANDOFF ══════════════════════════════"
    LATEST=$(ls -t "$REPO_ROOT/docs/collab/handoffs/" 2>/dev/null \
              | grep -v "handoff-template" | head -1 || true)
    if [[ -n "$LATEST" ]]; then
      cat "$REPO_ROOT/docs/collab/handoffs/$LATEST"
    else
      echo "(no handoffs found)"
    fi

    echo ""
    echo "═══ LOCK STATUS ═════════════════════════════════"
    cat "$REPO_ROOT/.clonewatch/agent-lock.json" 2>/dev/null \
      || echo "NO LOCK — workspace is free"

    echo ""
    echo "═══ MY PLANS & PENDING TASKS ════════════════════"
    ls "$REPO_ROOT/docs/temp/claude-personal/plans/"    2>/dev/null | head -10 || echo "(none)"
    ls "$REPO_ROOT/docs/temp/claude-personal/problems/" 2>/dev/null | head -5  || echo ""

    echo ""
    echo "✅ SESSION_START complete."
    echo "   Next: verify lock is free, claim it, then begin work."
    ;;

  # ── PLAN_APPROVED ────────────────────────────────────────────────────────
  PLAN_APPROVED)
    PLAN_DIR="$REPO_ROOT/docs/temp/claude-personal/plans"
    mkdir -p "$PLAN_DIR"
    PLAN_FILE="$PLAN_DIR/plan-$DATE_SHORT.md"

    cat > "$PLAN_FILE" <<PLANEOF
# Plan approved: $DATE_SHORT

Session: ${SESSION_ID:-unknown}
Timestamp: $TIMESTAMP
Message: ${MESSAGE:-<fill in>}

## Plan summary

[Fill in: what will be built/changed and why]

## Steps

1. [ ] Step one
2. [ ] Step two
3. [ ] Step three

## Files to change

- [ ] \`file/path\` — what changes

## Definition of done

- [ ] swift build passes
- [ ] swift test passes (if Swift files changed)
- [ ] Memory files updated
- [ ] current-state.md updated
- [ ] Commit ready

## Notes

[Any constraints, risks, or decisions recorded here]
PLANEOF

    echo ""
    echo "✅ PLAN_APPROVED"
    echo "   Stub created: $PLAN_FILE"
    echo ""
    echo "   REQUIRED ACTIONS:"
    echo "   1. Edit $PLAN_FILE — fill in the plan content"
    echo "   2. Update docs/collab/current-state.md pending section"
    echo "   3. If this is a major plan, append a note to clonewatch.md"
    ;;

  # ── TODO_DONE ────────────────────────────────────────────────────────────
  TODO_DONE)
    echo ""
    echo "✅ TODO_DONE — ${MESSAGE:-no message}"
    echo ""
    echo "   MANDATORY UPDATE CHECKLIST:"
    echo "   [ ] Architecture/runtime change?   → append to clonewatch.md"
    echo "   [ ] Product/feature change?         → append to CHANGELOG.md"
    echo "   [ ] Roadmap milestone closed?       → update docs/roadmap/"
    echo "   [ ] Closed a pending item?          → remove from current-state.md"
    echo "   [ ] New pending items created?      → add to current-state.md"
    echo "   [ ] External task resolved?         → external-update-task.sh --status DONE"
    echo "   [ ] Collab schema updated?          → run update-sqlite.sh"
    echo ""
    echo "   Run swift build && swift test before committing."
    ;;

  # ── FINDING ──────────────────────────────────────────────────────────────
  FINDING)
    FINDINGS_DIR="$REPO_ROOT/docs/temp/claude-personal/findings"
    mkdir -p "$FINDINGS_DIR"
    FINDING_FILE="$FINDINGS_DIR/finding-$DATE_SHORT.md"

    cat > "$FINDING_FILE" <<FINDINGEOF
# Finding: $DATE_SHORT

Session: ${SESSION_ID:-unknown}
Timestamp: $TIMESTAMP

## Summary

${MESSAGE:-<fill in>}

## Details

[What was found, where, and how]

## Why it matters

[Impact on the project — risk, opportunity, blocker, etc.]

## Recommended action

[What should be done, and by which agent]

## Status

- [ ] Finding documented
- [ ] Relevant party notified (docs/temp/<agent>/tasks/ or external-inbox)
- [ ] docs/project-memory.md updated (if significant)
- [ ] docs/collab/current-state.md updated (if blocker)
FINDINGEOF

    echo ""
    echo "✅ FINDING saved: $FINDING_FILE"
    echo ""
    echo "   REQUIRED ACTIONS:"
    echo "   1. Edit the finding file — fill in details, impact, and recommended action"
    echo "   2. If significant: append to docs/project-memory.md"
    echo "   3. If blocker: update docs/collab/current-state.md"
    echo "   4. If task for another agent: create task in docs/temp/<agent>/tasks/"
    ;;

  # ── PROBLEM_DETECTED ─────────────────────────────────────────────────────
  PROBLEM_DETECTED)
    PROBLEMS_DIR="$REPO_ROOT/docs/temp/claude-personal/problems"
    mkdir -p "$PROBLEMS_DIR"
    PROBLEM_FILE="$PROBLEMS_DIR/problem-$DATE_SHORT.md"

    cat > "$PROBLEM_FILE" <<PROBLEMEOF
# Problem Detected: $DATE_SHORT

Session: ${SESSION_ID:-unknown}
Timestamp: $TIMESTAMP
Severity: [HIGH / MEDIUM / LOW]

## Problem

${MESSAGE:-<fill in>}

## Root cause

[What is causing this — diagnosed or hypothesized]

## Impact

[What breaks or is blocked — who is affected]

## Proposed solution

[Steps to resolve]

## Escalation

- [ ] Documented here
- [ ] External task created (if needs another agent):  EXT-<ID>
- [ ] docs/collab/current-state.md blocker section updated
- [ ] docs/github/actions-root-cause-incident.md updated (if CI)
PROBLEMEOF

    echo ""
    echo "⚠️  PROBLEM_DETECTED — ${MESSAGE:-no message}"
    echo "   Problem stub saved: $PROBLEM_FILE"
    echo ""
    echo "   REQUIRED ACTIONS:"
    echo "   1. Edit problem file — fill in root cause, impact, solution"
    echo "   2. Update docs/collab/current-state.md → 'Active blocker' section"
    echo "   3. If external fix needed: tools/collab/external-new-task.sh"
    echo "   4. If CI: tools/collab/diagnose-github-actions.sh"
    ;;

  # ── SESSION_END ──────────────────────────────────────────────────────────
  SESSION_END)
    echo ""
    echo "   MANDATORY CLOSE CHECKLIST — complete every item before releasing lock:"
    echo ""
    echo "   BUILD & TEST"
    echo "   [ ] swift build passes"
    echo "   [ ] swift test passes (7/7)"
    echo ""
    echo "   MEMORY & DOCS"
    echo "   [ ] clonewatch.md — append operational memory update"
    echo "   [ ] docs/project-memory.md — append checkpoint (if arch changed)"
    echo "   [ ] CHANGELOG.md — updated"
    echo "   [ ] docs/sessions/records/<this-session>.md — finalized"
    echo ""
    echo "   STATE & HANDOFF"
    echo "   [ ] docs/collab/current-state.md updated:"
    echo "         - lock: NONE (will be released)"
    echo "         - git state: last commit hash"
    echo "         - pending: accurate list"
    echo "         - next agent: clear recommendation"
    echo "   [ ] tools/collab/handoff.sh called"
    echo ""
    echo "   COMMIT & PUSH"
    echo "   [ ] git add (only relevant files — no .sqlite, no .sqlite-shm, no .sqlite-wal)"
    echo "   [ ] git commit (conventional format: type(scope): summary + body)"
    echo "   [ ] git push origin <branch>"
    echo "   [ ] PR created if pushing to non-main branch"
    echo ""
    echo "   LOCK RELEASE"
    echo "   [ ] tools/collab/release-lock.sh called"
    echo ""
    echo "   ────────────────────────────────────────────────────"
    echo "   After lock is released, the workspace is free for Codex or next Claude session."
    ;;

  *)
    echo "❌ Unknown trigger: '$TRIGGER'"
    echo "Valid triggers: SESSION_START  PLAN_APPROVED  TODO_DONE  FINDING  PROBLEM_DETECTED  SESSION_END"
    exit 1
    ;;
esac

echo ""
echo "════════════════════════════════════════════════════"
echo "  CHECKPOINT $TRIGGER — $TIMESTAMP"
echo "════════════════════════════════════════════════════"
