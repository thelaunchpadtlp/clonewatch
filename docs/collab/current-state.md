# Current Project State

**This file is updated by each agent at session end. Always read this first.**

Last updated: 2026-04-14 by Claude Code (session `6e5936df-continued`, wave 3: governance + cleanup)

---

## Lock status

| Field | Value |
|---|---|
| Active lock | **FREE** — Codex session `codex-20260414-213200` released (PRs #4 and #5 merged) |
| Last holder | Codex (then Claude Code wave 3) |
| Lease context | Claude Code wave 3 adding governance doc, CHANGELOG, roadmap; PR #6 open with auto-merge |

---

## Git state

| Field | Value |
|---|---|
| Branch | `main` |
| Last stable commit | `6f62513` — merge commit for PR #4 |
| Local build | `swift build` PASSES |
| Local tests | `swift test` PASSES (7/7) |
| GitHub Actions | HEALTHY on merged PR #4 after ruleset correction |
| Pending PR | none |

---

## Active blocker

No active CI merge blocker at this moment.

Resolved chain:
- private-repo execution gating stopped after repository visibility moved to public
- GitHub default Code Scanning conflict removed by disabling default setup
- hidden merge blocker removed by aligning the `Protect main` ruleset with the actual emitted check names

Detailed incident:
- `docs/github/actions-root-cause-incident.md`
- external task: `docs/collab/external-inbox/EXT-ACTIONS-ROOTCAUSE-001.json`

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

PR #4 is now merged to `main`.

The final merge accepted these required checks:
- `build-and-test` ✅
- `CodeQL` ✅
- `validate-doc-history` ✅
- `enforce-memory-update` ✅

GitHub Actions: WORKING on the public repository.
CodeQL Default Setup: DISABLED so the custom workflow is authoritative.

## Pending items (priority order)

1. ✅ **TASK-CLAUDE-002** — guards updated (IGNORED_PATTERN filter, PR #6)
2. ✅ **TASK-CLAUDE-003** — clonewatch.md headers promoted to `###` (PR #6)
3. ✅ **TASK-CLAUDE-004** — LICENSE file added (PR #6)
4. ✅ **Auto-merge** — enabled at repo level; PR #6 has auto-merge active
5. ✅ **Repo visibility policy** — `docs/governance/repo-visibility-policy.md` created (PR #6)
6. **PR #6** — open, auto-merge set, CI running; needs Collab Guard + Project Records Guard to pass
7. **Sprint A**: run app end-to-end, test clone + verify + ledger flow; document UX findings
8. **Sprint A UI/UX**: see `docs/roadmap/macos-first-class-adoption.md` Sprint A section for full target list
9. **Next wave**: "Help Solve or Help Solve Better" subsystem design
10. **Gate B**: macOS signing/notarization pipeline
11. **Next tier**: Settings scene (Cmd+,), App Intents, Notification pipeline, Drag & drop, SF Symbols
12. **Pending**: Expanded accessibility, `.webloc` file for reports, app icon design

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
