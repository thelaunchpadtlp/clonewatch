# Current Project State

**This file is updated by each agent at session end. Always read this first.**

Last updated: 2026-04-14 by Claude Code (session `6e5936df`, Wave 3 — final close)

---

## Lock status

| Field | Value |
|---|---|
| Active lock | **NONE** — workspace is free |
| Last holder | Claude Code (session `6e5936df`) |
| Released at | 2026-04-14 ~20:15 UTC |

---

## Git state

| Field | Value |
|---|---|
| Branch | `main` |
| Last stable commit | `b3eed0d` — "feat(collabops): add CLAUDE.md, Sesiones Importantes, Temporales por Externo" |
| Local build | `swift build` PASSES |
| Local tests | `swift test` PASSES (7/7) |
| GitHub Actions | FAILING — billing issue (see blocker) |
| Pending PR | Wave 2 work to be pushed as PR (automations + session close) |

---

## Active blocker

**GitHub Actions — billing/payment issue**

- Cause: GitHub account payment has failed or spending limit needs to be increased
- Confirmed via: `gh run view 24418476339` → annotation clearly states billing error
- Previous diagnosis (minutes quota) was **incorrect** — corrected 2026-04-14
- The main branch has a ruleset "Protect main" requiring 4 CI checks before merge
- Detailed incident: `docs/github/actions-root-cause-incident.md`
- External task: `docs/collab/external-inbox/EXT-ACTIONS-ROOTCAUSE-001.json`
- Task for Codex: `docs/temp/codex-personal/tasks/TASK-CLAUDE-001-CI-FIX.md`

**Action required by user:**
1. Go to `https://github.com/settings/billing` (or org billing)
2. Resolve payment failure or increase spending limit
3. After billing is clear, tell Codex to open a PR for CI verification

**Good news:** Repo is now PUBLIC (screenshot confirmed 2026-04-14). A CodeQL
run auto-triggered. If billing is cleared, all standard workflow runs will be free
on the public repo.

---

## What was completed in Wave 1 of this Claude session (commit `b3eed0d`)

- Created `CLAUDE.md` (root anchor for Claude Code)
- Created `docs/claude/` companion files (session-guide, worktree-protocol, handoff-template)
- Created `docs/sessions/` subsystem (Sesiones Importantes) with schema and 2 session records
- Created `docs/temp/` subsystem (Temporales por Externo) with 16 agent folders
- Created `docs/collab/current-state.md` (this file)
- Updated `docs/collab/agent-capability-matrix.md` with Claude details
- Added navigation + ESTADO ACTUAL to `clonewatch.md`
- Left 3 task files for Codex in `docs/temp/codex-personal/tasks/`
- Updated `clonewatch.md`, `docs/project-memory.md`, `CHANGELOG.md`

## What was completed in Wave 2 of this Claude session (PR pending)

- Created `tools/collab/claude-checkpoint.sh` — automation trigger script
- Added Section 14 (Checkpoint Protocol) to `CLAUDE.md`
- Corrected TASK-CLAUDE-001 root cause (billing, not minutes)
- Wrote `docs/temp/codex-personal/BRIEFING-FROM-CLAUDE-20260414.md` for Codex
- Updated this file and session record
- Wrote session handoff

---

## CI state (final — all checks passing)

PR #4 (`claude/wave2-automations-20260414`) is MERGEABLE:
- CI build+test ✅ | Memory Guard ✅ | Collab Guard ✅ | Project Records Guard ✅ | CodeQL ✅
- Merge when Codex is ready (or user can merge directly on GitHub)

GitHub Actions: WORKING — repo is public, Actions runs are free and unlimited.
CodeQL Default Setup: ACTIVE (user enabled it; runs in Security tab, free on public repos).

## Pending items (priority order)

1. **Codex: Merge PR #4** — all checks passing, mergeable now
2. **Codex: TASK-CLAUDE-002** — update CI guard paths to exclude docs/temp/ and docs/sessions/
3. **Codex: TASK-CLAUDE-003** — add markdown headers to clonewatch.md body
4. **Codex: TASK-CLAUDE-004** — add proprietary LICENSE file (All Rights Reserved)
5. **TASK-CLAUDE-001 resolved** — CI now working (repo public = free Actions). No billing action needed.
6. **Sprint A (next Claude session)**: run app end-to-end, test clone + verify + ledger flow
7. **Next wave**: "Help Solve or Help Solve Better" subsystem design
8. **Gate B**: macOS signing/notarization pipeline
9. **NEXT tier**: Settings scene (Cmd+,), App Intents, Notification pipeline
10. **Pending**: Expanded accessibility, `.webloc` file for reports

---

## Next recommended agent

**Codex** — Claude is pausing for a Mac app update.

Priority path for Codex:
```bash
# 1. Read full briefing Claude wrote for you:
cat docs/temp/codex-personal/BRIEFING-FROM-CLAUDE-20260414.md

# 2. Your tasks in order:
cat docs/temp/codex-personal/tasks/TASK-CLAUDE-001-CI-FIX.md
cat docs/temp/codex-personal/tasks/TASK-CLAUDE-002-GUARDS-UPDATE.md
cat docs/temp/codex-personal/tasks/TASK-CLAUDE-003-CLONEWATCH-RESTRUCTURE.md
```

**When Claude returns:**
```bash
cat CLAUDE.md  # (loaded automatically)
cat docs/collab/current-state.md  # this file
cat docs/collab/handoffs/$(ls -t docs/collab/handoffs/ | grep -v template | head -1)
```
