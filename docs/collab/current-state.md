# Current Project State

**This file is updated by each agent at session end. Always read this first.**

Last updated: 2026-04-14 by Codex (session `codex-20260414-203500`, post-Claude verification)

---

## Lock status

| Field | Value |
|---|---|
| Active lock | **HELD** — Codex (session `codex-20260414-203500`) |
| Last holder | Codex |
| Lease context | Documentation + CI/ruleset hardening after Claude PR verification |

---

## Git state

| Field | Value |
|---|---|
| Branch | `claude/wave2-automations-20260414` |
| Last stable commit | `4ce5644` — latest commit on PR #4 before Codex follow-up |
| Local build | `swift build` PASSES |
| Local tests | `swift test` PASSES (7/7) |
| GitHub Actions | HEALTHY on PR #4; follow-up hardening in progress |
| Pending PR | PR #4 open and green, but merge currently blocked by required-check design mismatch being fixed |

---

## Active blocker

**Merge gating mismatch on PR #4**

- Cause: ruleset `Protect main` requires `Docs History Validation`, but that workflow was path-filtered and did not emit a check on unrelated PRs
- Secondary resolved cause: custom CodeQL workflow conflicted with GitHub Code Scanning default setup
- Confirmed via:
  - `gh api repos/thelaunchpadtlp/clonewatch/rulesets/15050922`
  - `gh api repos/thelaunchpadtlp/clonewatch/code-scanning/default-setup`
  - `gh pr view 4 --json statusCheckRollup`
- Detailed incident: `docs/github/actions-root-cause-incident.md`
- External task: `docs/collab/external-inbox/EXT-ACTIONS-ROOTCAUSE-001.json`
- Task for Codex: `docs/temp/codex-personal/tasks/TASK-CLAUDE-001-CI-FIX.md`

**Current Codex fix path:**
1. update `Docs History Validation` so it always emits a check on PRs to `main`
2. harden custom CodeQL workflow (`@v4` + explicit `swift build`)
3. push follow-up to PR branch
4. merge PR #4 once required checks are all satisfied

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

## What was completed in Wave 2 of this Claude session (PR #4)

- Created `tools/collab/claude-checkpoint.sh` — automation trigger script
- Added Section 14 (Checkpoint Protocol) to `CLAUDE.md`
- Corrected TASK-CLAUDE-001 root cause (billing, not minutes)
- Wrote `docs/temp/codex-personal/BRIEFING-FROM-CLAUDE-20260414.md` for Codex
- Updated this file and session record
- Wrote session handoff

---

## CI state (verified by Codex)

PR #4 (`claude/wave2-automations-20260414`) has green PR checks:
- CI build+test ✅
- Memory Guard ✅
- Collab Guard ✅
- Project Records Guard ✅
- CodeQL ✅

However, merge is still blocked until `Docs History Validation` is made to report consistently for PRs required by the ruleset.

GitHub Actions: WORKING on the public repository.
CodeQL Default Setup: DISABLED so the custom workflow is authoritative.

## Pending items (priority order)

1. **Codex: land follow-up fix for `Docs History Validation` + CodeQL hardening**
2. **Codex: merge PR #4**
3. **Codex: TASK-CLAUDE-002** — update CI guard paths to exclude docs/temp/ and docs/sessions/
4. **Codex: TASK-CLAUDE-003** — add markdown headers to clonewatch.md body
5. **Codex: TASK-CLAUDE-004** — add proprietary LICENSE file (All Rights Reserved)
6. **Sprint A**: run app end-to-end, test clone + verify + ledger flow
7. **Next wave**: "Help Solve or Help Solve Better" subsystem design
8. **Gate B**: macOS signing/notarization pipeline
9. **Next tier**: Settings scene (Cmd+,), App Intents, Notification pipeline
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
