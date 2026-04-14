# Current Project State

**This file is updated by each agent at session end. Always read this first.**

Last updated: 2026-04-14 by Claude Code (session `6e5936df`)

---

## Lock status

| Field | Value |
|---|---|
| Active lock | **NONE** — workspace is free |
| Last holder | Codex (session `codex-20260414-185150`) |
| Released at | 2026-04-14 ~18:52 UTC |

---

## Git state

| Field | Value |
|---|---|
| Branch | `main` |
| Last stable commit | `95b9fae` — "docs(collabops): record session pause guidance" |
| Local build | `swift build` PASSES |
| Local tests | `swift test` PASSES (7/7) |
| GitHub Actions | ALL FAILING — see blocker below |

---

## Active blocker

**GitHub Actions — all workflows fail pre-step (`steps: []`)**

- Cause: GitHub Actions minutes quota exhausted for private repo (account-level, not code)
- Fix required: Make repo public OR upgrade GitHub plan
- Detailed incident: `docs/github/actions-root-cause-incident.md`
- External task: `docs/collab/external-inbox/EXT-ACTIONS-ROOTCAUSE-001.json`
- Task for Codex to monitor: `docs/temp/codex-personal/tasks/TASK-CLAUDE-001-CI-FIX.md`

**Action required by user (not Codex, not Claude):**
1. Go to `github.com/thelaunchpadtlp/clonewatch`
2. Settings → General → Danger Zone → Change repository visibility → **Public**
3. After that, tell Codex to push an empty commit to trigger CI

---

## What was just completed (this Claude session)

- Created `CLAUDE.md` (root anchor for Claude Code)
- Created `docs/claude/` companion files (session-guide, worktree-protocol, handoff-template)
- Created `docs/sessions/` subsystem (Sesiones Importantes) with schema and 2 session records
- Created `docs/temp/` subsystem (Temporales por Externo) with 16 agent folders
- Created `docs/collab/current-state.md` (this file)
- Updated `docs/collab/agent-capability-matrix.md` with Claude details
- Added SQLite WAL/SHM to `.gitignore`
- Added TOC to `clonewatch.md`
- Left 3 tasks for Codex in `docs/temp/codex-personal/tasks/`
- Updated `clonewatch.md`, `docs/project-memory.md`, `CHANGELOG.md`

---

## Pending integrals (priority order)

1. **Fix GitHub Actions** (user action: make repo public)
2. **Codex: Update CI guards** to exclude `docs/temp/` and `docs/sessions/` from guard checks (`TASK-CLAUDE-002`)
3. **Codex: Add navigation to clonewatch.md body** — add section headers to the 500-line history (`TASK-CLAUDE-003`)
4. **Next wave design**: "Help Solve or Help Solve Better" subsystem
5. **Gate B**: macOS signing/notarization pipeline
6. **NEXT tier**: Settings scene (Cmd+,), App Intents, Notification pipeline
7. **Pending integral**: Expanded accessibility (keyboard, VoiceOver)
8. **Pending integral**: `.webloc` file for reports (historical user request)

---

## Next recommended agent

**Either Codex or Claude** — both can proceed.

For Codex:
```bash
cat docs/temp/codex-personal/tasks/TASK-CLAUDE-001-CI-FIX.md
cat docs/temp/codex-personal/tasks/TASK-CLAUDE-002-GUARDS-UPDATE.md
cat docs/temp/codex-personal/tasks/TASK-CLAUDE-003-CLONEWATCH-RESTRUCTURE.md
```

For Claude:
```bash
cat CLAUDE.md  # (loaded automatically)
cat docs/collab/current-state.md  # this file
cat docs/collab/handoffs/$(ls -t docs/collab/handoffs/ | head -1)
```
