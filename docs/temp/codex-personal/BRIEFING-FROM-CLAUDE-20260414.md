# Briefing from Claude Code → Codex
# Session: 6e5936df | Date: 2026-04-14 | Priority: READ BEFORE WORKING

---

## TL;DR — 3 things you must do, in order

1. **Read TASK-CLAUDE-001** — CI is broken (billing issue, not minutes). Fix it first.
2. **Read TASK-CLAUDE-002** — Update CI guards to exclude docs/temp/ and docs/sessions/.
3. **Read TASK-CLAUDE-003** — Add markdown headers to clonewatch.md body.

All three task files are in `docs/temp/codex-personal/tasks/` and are written with
near-zero interpretation needed — every command is spelled out exactly.

---

## What Claude did in this session

### Files created (53 total, commit `b3eed0d` on main)

**Operational anchor for Claude Code:**
- `CLAUDE.md` — root-level file (Claude Code reads it automatically at every session)
- `docs/claude/session-guide.md` — full step-by-step guide for full-writer and externo modes
- `docs/claude/worktree-protocol.md` — when to use worktrees vs write to main
- `docs/claude/handoff-template.md` — handoff format reference

**Sesiones Importantes subsystem (`docs/sessions/`):**
- `docs/sessions/README.md` — subsystem overview and policy
- `docs/sessions/schema/session-record.schema.json` — JSON schema for session records
- `docs/sessions/index.md` — master table of all important sessions
- `docs/sessions/records/codex-session-20260414-001.md` — your founding session record
- `docs/sessions/records/claude-session-20260414-001.md` — Claude's session record

**Temporales por Externo subsystem (`docs/temp/`):**
- `docs/temp/README.md` — policy and rules (read this — it defines when to use temp vs main)
- `docs/temp/_inventory.md` — live inventory of all temp folder contents
- `docs/temp/_event-log.md` — append-only event log
- `docs/temp/{16 agent folders}/` — one private workspace per agent:
  codex-personal, codex-team, chatgpt-personal, chatgpt-team, antigravity,
  vertex-ai, gemini, cursor, lovable, replit, claude-personal, claude-team,
  perplexity-personal, perplexity-team, manus-personal, manus-team
- Each folder has `.profile.json` and `README.md`

**Your task folder (`docs/temp/codex-personal/tasks/`):**
- `TASK-CLAUDE-001-CI-FIX.md` — fix GitHub Actions (now with corrected root cause)
- `TASK-CLAUDE-002-GUARDS-UPDATE.md` — update CI guards
- `TASK-CLAUDE-003-CLONEWATCH-RESTRUCTURE.md` — add markdown headers to clonewatch.md

**Live state reference:**
- `docs/collab/current-state.md` — always-updated one-page project state (read this first each session)

**Modified files:**
- `clonewatch.md` — added NAVEGACIÓN RÁPIDA, ESTADO ACTUAL, GLOSARIO at top
- `docs/collab/agent-capability-matrix.md` — updated Claude row with operating notes
- `docs/project-memory.md` — new checkpoint appended
- `CHANGELOG.md` — updated
- `.gitignore` — added `*.sqlite-shm` and `*.sqlite-wal`

**New in Wave 2 of this session (commit TBD — see PR):**
- `tools/collab/claude-checkpoint.sh` — automation trigger script (see below)
- `CLAUDE.md` section 14 — Checkpoint Protocol (automation docs)
- This briefing file
- Updated `TASK-CLAUDE-001` with corrected CI root cause

---

## The logic and spirit behind Claude's decisions

### Why CLAUDE.md at root?
Claude Code reads files named `CLAUDE.md` automatically at every session start.
Putting it at root means Claude is always oriented — no manual reading needed.

### Why docs/temp/ instead of just worktrees?
Worktrees are ephemeral — they disappear when you delete the branch.
The Temporales system gives each external agent a **persistent private workspace**
that survives across sessions. This is where Claude leaves plans for herself,
where you can leave findings, where future agents can pre-stage work.

### Why docs/sessions/?
Two JSONL export files were analyzed (~4,749 lines for Codex, ~117 for Claude).
These files can't go to git (too large). But the DECISIONS and CONTEXT from those
sessions are project-critical. The Sesiones Importantes system preserves the
knowledge without bloating the repo.

### Why current-state.md?
Before this session there was no single "what is the project's current situation"
file. Every agent was reading 5+ files to reconstruct state. `current-state.md`
is the canonical one-pager — always current because the single writer updates it
before every lock release.

### Why the Checkpoint Protocol (claude-checkpoint.sh)?
Claude's risk in this project is **memory drift** — doing great work in one session,
then starting the next session without context. The checkpoint script forces
documentation at key moments (plan approved, todo done, finding, problem, session end).
It doesn't replace human judgment — it reminds Claude what to update and creates stubs.

### Why create your task files instead of just doing the work?
CI is broken. Without CI, pushing code to main is guarded by branch protection rules
that require 4 status checks to pass. Claude can't bypass that. Claude also doesn't
have persistent terminal sessions that survive context resets. Tasks are written
to be executable by you with zero interpretation.

---

## Current state of GitHub Actions CI

**This is the most critical open item.**

Previous diagnosis: "private repo free-tier minutes exhausted"  → **WRONG**

Actual root cause (confirmed via `gh run view 24418476339`):
```
"The job was not started because recent account payments have failed or
your spending limit needs to be increased."
```

What happened after the repo was made public:
- A CodeQL run auto-triggered ("in_progress" at last check)
- The main branch has a ruleset "Protect main" requiring 4 checks before push:
  CI, CodeQL, Docs History Validation, Memory Guard
- Direct push to main is therefore blocked until checks pass
- You must create a PR, let CI run on the PR branch, then merge

See TASK-CLAUDE-001 for exact commands.

**User action required:** Check GitHub billing at `https://github.com/settings/billing`
and resolve any payment failure or spending limit issue first.

---

## Your tasks — in order

### TASK-CLAUDE-001: Fix GitHub Actions CI (HIGH PRIORITY)

File: `docs/temp/codex-personal/tasks/TASK-CLAUDE-001-CI-FIX.md`

Steps (updated — re-read the file, not this summary):
1. User resolves billing issue (you can't do this, tell the user)
2. Push `claude/ecstatic-noether` branch and open PR
3. Wait for CI to pass
4. Merge PR
5. Update incident doc, external task, memory
6. Push to main

Critical: Don't push directly to main — the ruleset will reject it.

### TASK-CLAUDE-002: Update CI Guards (HIGH, depends on TASK-001)

File: `docs/temp/codex-personal/tasks/TASK-CLAUDE-002-GUARDS-UPDATE.md`

Add `docs/temp/**` and `docs/sessions/**` to paths-ignore in:
- `.github/workflows/memory-guard.yml`
- `.github/workflows/collab-guard.yml`
- `.github/workflows/project-records-guard.yml`

Also add `CLAUDE.md` to Memory Guard trigger paths.

Why: Without this, any note you write in your docs/temp/codex-personal/ folder
will trigger Memory Guard, which will then fail because it's looking for memory
changes in unrelated files. This will create CI noise on every agent session.

### TASK-CLAUDE-003: Restructure clonewatch.md (MEDIUM)

File: `docs/temp/codex-personal/tasks/TASK-CLAUDE-003-CLONEWATCH-RESTRUCTURE.md`

500-line flat history → navigable sections with markdown headers.
The task file has exact Python code to run. Don't do this by hand.

---

## Tools Claude created for you

### `tools/collab/claude-checkpoint.sh`

```bash
# Run at session start to surface all context:
tools/collab/claude-checkpoint.sh --trigger SESSION_START --session-id "$SESSION_ID"

# Run when you complete a significant task:
tools/collab/claude-checkpoint.sh --trigger TODO_DONE \
  --session-id "$SESSION_ID" --message "Updated CI guards"

# Run at session end to get the mandatory close checklist:
tools/collab/claude-checkpoint.sh --trigger SESSION_END --session-id "$SESSION_ID"
```

This script is for Claude (the triggers map to Claude's memory obligations) but
you can run it too — SESSION_END checklist in particular is useful for any agent.

### `docs/collab/current-state.md`

Always read this before doing anything. It's the canonical one-pager:
- Who holds the lock
- Last stable commit
- Active blockers
- Pending items (priority-ordered)
- Which agent should work next

---

## Suggestions for the future (not tasks — just observations)

1. **Help Solve / Help Solve Better subsystem** — deferred by both Claude and you.
   This is the next major product feature after Gate A closes.
   Start design in `docs/temp/codex-personal/plans/` first.

2. **Gate B (signing/notarization)** — the macOS signing pipeline has no code yet.
   See `docs/roadmap/v1-productized-gates.md` for the Gate B definition.

3. **Session records are now structured** — when your next Codex session ends,
   write a record to `docs/sessions/records/codex-session-20260414-002.md` (or
   whatever the date is). Schema: `docs/sessions/schema/session-record.schema.json`.

4. **Inventory update** — after you work in your temp folder, update
   `docs/temp/_inventory.md` to reflect what you added/removed/promoted.

5. **The next-wave intake document** — see `docs/project-memory.md` at the bottom.
   There are deferred items there waiting for design work.

---

## How to read the docs Claude created

| If you want to know... | Read this file |
|---|---|
| What state is the project in right now? | `docs/collab/current-state.md` |
| What are the rules for writing to the repo? | `docs/collab/protocol.md` |
| What is each agent capable of? | `docs/collab/agent-capability-matrix.md` |
| What did Claude do and why? | `docs/sessions/records/claude-session-20260414-001.md` |
| What did Codex do in the founding session? | `docs/sessions/records/codex-session-20260414-001.md` |
| How does the Temporales system work? | `docs/temp/README.md` |
| How does Claude operate? | `CLAUDE.md` (and `docs/claude/session-guide.md`) |
| What needs to be built next? | `docs/roadmap/macos-first-class-adoption.md` |
| What are the V1 gates? | `docs/roadmap/v1-productized-gates.md` |
| What changed in this session? | `CHANGELOG.md` |

---

## Resuming after Claude's session closes

Claude will be closing this session to allow a Mac app update.
The session will be paused, not deleted — Claude can resume the same thread later.

While Claude is away, you can work freely:
- The lock is NONE (workspace is free)
- All your task files are ready
- Start with TASK-CLAUDE-001 (CI fix)

When Claude returns, she will read:
1. `docs/collab/current-state.md`
2. `docs/collab/handoffs/<latest>-Claude.md`
3. `CLAUDE.md` (auto-loaded)

So keep `current-state.md` up to date and write a handoff when your session ends.

---

*Written by: Claude Code, session 6e5936df, 2026-04-14*
*For: ChatGPT-Codex*
*This file lives in docs/temp/codex-personal/ — it's your private workspace.*
