# Changelog

All notable project changes are recorded here.

## 2026-04-14

### Added (Claude Code session — wave 2: checkpoint automation)

- `tools/collab/claude-checkpoint.sh` — automation trigger script for Claude; 6 trigger types
  (SESSION_START, PLAN_APPROVED, TODO_DONE, FINDING, PROBLEM_DETECTED, SESSION_END)
- `CLAUDE.md` Section 14 — Checkpoint Protocol: defines when Claude calls the script and what each trigger updates
- `docs/temp/codex-personal/BRIEFING-FROM-CLAUDE-20260414.md` — full context handoff for Codex
- `docs/collab/handoffs/20260414-201500-Claude.md` — session close handoff record

### Changed (Claude Code session — wave 2)

- `docs/temp/codex-personal/tasks/TASK-CLAUDE-001-CI-FIX.md` — corrected root cause from "minutes quota" to billing/payment failure
- `docs/collab/current-state.md` — updated for session close state
- `docs/sessions/records/claude-session-20260414-001.md` — finalized with wave 2 content
- `clonewatch.md` — appended wave 2 operational memory update

---

### Added (Claude Code session — externo analyst pass)

- `CLAUDE.md` — root-level anchor for all Claude Code sessions (reads automatically)
- `docs/claude/session-guide.md`, `worktree-protocol.md`, `handoff-template.md` — Claude operational companions
- `docs/sessions/` — Sesiones Importantes subsystem: schema, session index, records for Codex and Claude founding sessions
- `docs/temp/` — Temporales por Externo subsystem: 16 agent workspaces (codex-personal, codex-team, chatgpt-personal, chatgpt-team, antigravity, vertex-ai, gemini, cursor, lovable, replit, claude-personal, claude-team, perplexity-personal, perplexity-team, manus-personal, manus-team)
- `docs/collab/current-state.md` — live project state quick reference (always read first)
- 3 Codex task files in `docs/temp/codex-personal/tasks/` (CI fix, guards update, clonewatch restructure)

### Changed (Claude Code session)

- `clonewatch.md` — added navigation TOC, ESTADO ACTUAL block, GLOSARIO, and OPERATIONAL MEMORY UPDATES section marker at top
- `docs/collab/agent-capability-matrix.md` — added Claude Code-specific operating notes and updated Claude row

### Added

- macOS first-class adoption roadmap (`docs/roadmap/macos-first-class-adoption.md`)
- prioritization decision framework (`docs/decisions/macos-prioritization-framework.md`)
- plan-approval memory-first policy
- session traceability policy and registry
- run progress architecture (phase model + serializable snapshots)
- run progress export artifact (`run-progress.json`)
- CollabOps protocol and governance docs for multi-agent coordination
- JSON schemas for `agent-run-record`, `handoff-record`, and `lock-record`
- single-writer operational scripts (`begin-session`, `claim-lock`, `record-step`, `handoff`, `release-lock`, `recover-interrupted-session`, `self-test`, `update-sqlite`)
- `Collab Guard` GitHub Actions workflow
- Actions triage guide (`docs/github/actions-triage.md`)
- external delegation channels:
  - `docs/collab/external-inbox/`
  - `docs/collab/external-outbox/`
- external task contracts:
  - `docs/schemas/external-task-request.schema.json`
  - `docs/schemas/external-task-event.schema.json`
- external task scripts:
  - `external-new-task.sh`
  - `external-claim-task.sh`
  - `external-update-task.sh`
- GitHub auth/access policy (`docs/github/auth-access-policy.md`)
- Codex commit/PR instruction source (`docs/github/codex-commit-pr-instructions.md`)
- Actions diagnostics script (`tools/collab/diagnose-github-actions.sh`)
- GitHub Actions root-cause incident doc (`docs/github/actions-root-cause-incident.md`)
- external high-priority investigation task for Actions blocker (`EXT-ACTIONS-ROOTCAUSE-001`)

### Changed

- Copy engine now includes dry-run estimate logging before copy execution
- verification now respects selected mode (`size-only`, `metadata`, checksum modes)
- runtime now emits progress timeline events across all phases
- Run UI now shows timeline/progress narrative and accessibility-focused status cues
- Dependabot cadence/limits tuned to reduce CI noise
- CodeQL and Memory Guard bot-noise handling refined
- Memory and project-record guards now include CollabOps-sensitive paths (`tools/collab`, `docs/collab`, `docs/schemas`)
- CI now uses bot-noise filter and per-ref concurrency for cleaner signal
- Collab schema expanded with `external_tasks` and `external_task_events` tables
- README now includes beginner-friendly local app test instructions and explicit guidance for Claude/externos during an active writer session
- project memory now records the session-pause handoff and the `.claude/` local-tool-state observation

### Fixed

- robust SQLite ledger import path for runtime/test stability
- stale/interrupted-session handling process documented and operationalized with recovery checklist and lock lifecycle controls
