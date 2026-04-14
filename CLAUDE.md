# CLAUDE.md — Operating Instructions for Claude Code / Claude Desktop

Date: 2026-04-14
Owner: The Launch Pad - TLP
Maintained by: Claude (update this file each session)

---

## 1. Who I am in this project

**Role:** Full Writer (with lock protocol)
**Agent ID:** `Claude Code` (CLI) or `Claude Desktop` depending on access method
**Default mode:** `single-writer` — one active writer at a time
**Lock required to write:** Yes. No mutations to `main` without a claimed lock.

**From the capability matrix (`docs/collab/agent-capability-matrix.md`):**
- Strength: Strong coding, refactor, analysis, multi-file coordination
- Risk: Can drift across sessions if handoff discipline is weak
- Mitigation: This file + session-guide + always read last handoff before working

---

## 2. Before every session — mandatory checklist

Run these commands IN ORDER before touching any file:

```bash
# 1. Go to repo root (not worktree)
cd /Users/Shared/Pruebas/CloneWatch

# 2. Check lock
cat .clonewatch/agent-lock.json 2>/dev/null || echo "NO LOCK — workspace is free"

# 3. Read last handoff
ls -t docs/collab/handoffs/ | head -3
cat docs/collab/handoffs/$(ls -t docs/collab/handoffs/ | head -1)

# 4. Read current state
cat docs/collab/current-state.md

# 5. Check git status and sync
git fetch origin && git status -sb

# 6. Read my own pending plans
ls docs/temp/claude-personal/plans/ 2>/dev/null
```

If a lock exists and is NOT expired, do NOT claim it. Use external-inbox instead.
If the lock is expired (check `lease_expires_at_epoch` vs `date +%s`), use recovery flow.

---

## 3. How to claim the lock and begin a session

```bash
cd /Users/Shared/Pruebas/CloneWatch
SESSION_ID="claude-$(date +%Y%m%d-%H%M%S)"
tools/collab/begin-session.sh \
  --owner "The Launch Pad - TLP" \
  --agent-app "Claude Code" \
  --session-id "$SESSION_ID" \
  --mode "single-writer" \
  --ttl-minutes 90
echo "Session ID: $SESSION_ID"
```

**IMPORTANT:** Note the SESSION_ID. Use it in every subsequent script call.

---

## 4. The full state machine (Single Writer)

```
BEGIN → CLAIM_LOCK → SYNC → WORK → VALIDATE → RECORD → PUSH → HANDOFF → RELEASE
```

Each state must be logged. The scripts handle logging automatically.

**WORK phase rules:**
- Prefer worktrees for large changes (`claude/ecstatic-noether` or create a new one)
- For small docs-only changes, write directly to main branch after lock is claimed
- Never push without running `swift build && swift test` first
- Update `clonewatch.md` and `docs/project-memory.md` when architecture/behavior changes

**VALIDATE — required checks:**
```bash
cd /Users/Shared/Pruebas/CloneWatch
swift build 2>&1 | tail -5
swift test 2>&1 | tail -10
```

**RECORD — after every meaningful step:**
```bash
tools/collab/record-step.sh \
  --owner "The Launch Pad - TLP" \
  --agent-app "Claude Code" \
  --session-id "$SESSION_ID" \
  --event "VALIDATE" \
  --message "swift build and swift test passed."
```

---

## 5. How to close a session

```bash
# 1. Write handoff
tools/collab/handoff.sh \
  --owner "The Launch Pad - TLP" \
  --agent-app "Claude Code" \
  --session-id "$SESSION_ID" \
  --summary "Brief description of what was done and what is pending."

# 2. Update current-state.md
# Edit docs/collab/current-state.md to reflect new state

# 3. Release lock
tools/collab/release-lock.sh \
  --owner "The Launch Pad - TLP" \
  --agent-app "Claude Code" \
  --session-id "$SESSION_ID"
```

---

## 6. Worktree protocol

**When to use a worktree:**
- Changes involve Swift code (Sources/, Tests/)
- Changes are broad (touching >5 files)
- Codex might be starting a session soon (worktrees isolate work)

**When to write directly to main (after claiming lock):**
- Docs-only changes (docs/, CLAUDE.md, CHANGELOG.md, clonewatch.md)
- Single-file edits with obvious scope

**Worktree convention:**
- Branch name: `claude/YYYYMMDD-description` (e.g., `claude/20260414-add-sessions-subsystem`)
- Worktree path: `/Users/Shared/Pruebas/CloneWatch/.claude/worktrees/<branch-slug>/`

**Current active worktree:** `claude/ecstatic-noether` at `/Users/Shared/Pruebas/CloneWatch/.claude/worktrees/ecstatic-noether`

**To create a new worktree:**
```bash
cd /Users/Shared/Pruebas/CloneWatch
git worktree add .claude/worktrees/my-feature claude/my-feature 2>/dev/null || \
  git worktree add .claude/worktrees/my-feature -b claude/my-feature
```

---

## 7. Memory obligations

These files MUST be updated when architecture/runtime/automation changes:
- `clonewatch.md` — append a new dated operational update
- `docs/project-memory.md` — append a new checkpoint

These files MUST be updated for major product changes:
- `CHANGELOG.md`
- `docs/roadmap/macos-first-class-adoption.md`

**Format for clonewatch.md entries:**
```
Operational memory update (April 14, 2026 - <topic>)

- <bullet point describing what changed>
- <bullet point with what is pending>
```

---

## 8. Commit message format

```
<type>(<scope>): <short imperative summary>

Why: <business/user reason>
What: <key changes>
Validation: <build/test results>
Collab trace: agent_app=Claude Code, session_id=<id>
Records updated: <files updated>
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`, `perf`
Scopes: `core`, `ui`, `ledger`, `inventory`, `verify`, `collabops`, `docs`, `ci`, `github`, `roadmap`, `sessions`, `temp`

---

## 9. External delegation (when I am NOT the active writer)

If Codex or another agent holds the lock, I operate as an **externo analyst**:

1. Read everything (no lock needed to read)
2. Leave plans in `docs/temp/claude-personal/plans/`
3. Leave tasks for Codex in `docs/temp/codex-personal/tasks/`
4. For formal tasks, use the inbox:
   ```bash
   tools/collab/external-new-task.sh \
     --task-id "EXT-CLAUDE-001" \
     --requester "Claude Code" \
     --title "Task title" \
     --description "Description" \
     --priority "high"
   ```

---

## 10. Recovery from interrupted session

```bash
cd /Users/Shared/Pruebas/CloneWatch

# 1. Check lock state
cat .clonewatch/agent-lock.json
date +%s  # compare with lease_expires_at_epoch

# 2. If lock is expired, recover:
NEW_SESSION_ID="claude-$(date +%Y%m%d-%H%M%S)-recovery"
tools/collab/recover-interrupted-session.sh \
  --owner "The Launch Pad - TLP" \
  --agent-app "Claude Code" \
  --session-id "$NEW_SESSION_ID"

# 3. Re-sync git
git fetch origin && git status -sb

# 4. Run checks before continuing
swift build && swift test
```

---

## 11. Key reference files

| File | Purpose |
|---|---|
| `docs/collab/protocol.md` | Single Writer state machine and rules |
| `docs/collab/agent-capability-matrix.md` | All agent roles and capabilities |
| `docs/collab/current-state.md` | Current project state (always read first) |
| `docs/collab/recovery-checklist.md` | Recovery procedure for interrupted sessions |
| `docs/github/codex-commit-pr-instructions.md` | Commit/PR format for all agents |
| `docs/roadmap/macos-first-class-adoption.md` | Product roadmap and pending items |
| `docs/roadmap/v1-productized-gates.md` | V1 gates (Gate A through D) |
| `docs/sessions/index.md` | All important session records |
| `docs/temp/claude-personal/plans/` | My pending plans and analyses |
| `docs/temp/codex-personal/tasks/` | Tasks I leave for Codex |

---

## 12. What I must NOT do without user confirmation

- Push to `main` with unresolved `swift test` failures
- Delete or rename files already tracked in git
- Merge Codex's branch into main
- Change `.github/workflows/` files without updating memory
- Write into another externo's `docs/temp/<externo>/` folder
- Bypass the lock by writing directly to main when another agent holds it

---

## 13. How I interact with Codex

**Receiving from Codex:**
1. Read last handoff: `docs/collab/handoffs/<latest>-Codex.md`
2. Read `docs/collab/current-state.md`
3. Check pending tasks left for me: `docs/temp/claude-personal/tasks/`
4. Claim lock only after verifying Codex's lock is released

**Handing off to Codex:**
1. Write my handoff: `tools/collab/handoff.sh ...`
2. Leave tasks in `docs/temp/codex-personal/tasks/TASK-*.md`
3. Update `docs/collab/current-state.md` with clear "next recommended agent" field
4. Release lock

---

*This file is read automatically by Claude Code at session start.*
*Update the "Date" field and any changed sections when you modify this file.*
