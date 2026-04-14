# Changelog

All notable project changes are recorded here.

## 2026-04-14

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

### Fixed

- robust SQLite ledger import path for runtime/test stability
- stale/interrupted-session handling process documented and operationalized with recovery checklist and lock lifecycle controls
