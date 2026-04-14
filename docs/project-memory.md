# CloneWatch Project Memory

## Current Direction

CloneWatch v2 is evolving from a Python comparison script into a native macOS platform for cloning, reinforcement, verification, storage migration, disk-topology awareness, and documentary evidence.

## Major Requirements Captured So Far

- support folder-to-folder, folder-to-volume, volume-to-folder, and volume-to-volume workflows
- generate durable audit bundles in central storage and mirror them into source and destination
- preserve the original ChatGPT project history by copying PDFs, extracting them, and reconstructing a canonical transcript
- support efficient reinforcement of an existing clone by transferring only changed files
- keep web-readable reports so evidence can be opened from another device
- become storage-topology aware, closer in spirit to Disk Utility plus migration safety

## New Platform Constraints

- the app should ask for what it can ask for directly, especially file-system access through native pickers
- Full Disk Access cannot be silently granted by the app and must be explained/guided
- future destructive operations must go through a privileged helper rather than running the full GUI as root
- iCloud Drive and shared iCloud folders need special risk handling because hydration and sync state can break strict clone assumptions
- using `/` directly as a clone root is too dangerous and should be blocked or heavily constrained

## Strategic Direction

CloneWatch should become a storage migration orchestrator with five power bands:

1. clone
2. verify
3. document
4. migrate
5. DiskOps

DiskOps should itself be split into:

- read-only topology inspection
- safe operations
- destructive operations

## Evidence Philosophy

Every important operation should leave behind enough evidence to answer:

- what existed before
- what was copied
- what changed
- what risks were known
- what permissions were needed
- whether the source can be archived or deleted safely

## Operational Snapshot (April 14, 2026)

- GitHub sync was repaired and the project is now operating from `main` with normal push/fetch behavior through GitHub Desktop.
- Raw chat-history PDFs are intentionally local-only because they exceed GitHub's 100 MB limit per file.
- The repo keeps durable references to those local PDFs through:
  - `docs/chat-history/raw-pdfs/README.local.md`
  - `docs/chat-history/raw-pdfs.manifest.tsv`
- Reconstructed/extracted history remains versioned in git (`docs/chat-history/extracted/` and `docs/chat-history/canonical-transcript.md`).
- CI hardening was completed:
  - fixed `README.md` conflict markers
  - made docs-history workflow resilient when raw PDFs are absent on CI runners
- GitHub Actions status reading for operators:
  - green = passed
  - yellow = queued/running
  - red = failed
  - Dependabot runs are background maintenance and may appear noisy

## Memory Discipline Rule

Before compacting context, append a dated summary of:

- what changed
- what remains pending
- what warnings/noise can be safely ignored

## Memory Guard Institutionalized (April 14, 2026)

- Memory update before context compaction is now a core project feature, not just a chat habit.
- A new GitHub Actions workflow (`Memory Guard`) now enforces this rule at repository level.
- Guard rule: if architecture/runtime/automation files change, at least one memory file must be updated in the same change set:
  - `clonewatch.md`
  - `docs/project-memory.md`
- This converts project memory into an explicit governance mechanism and protects continuity for future sessions.

## Actions Snapshot (April 14, 2026)

- Latest tracked commit in focus: `f59a166`.
- Current status at update time:
  - `CI`: passed (green)
  - `Memory Guard`: passed (green)
  - `CodeQL`: running (yellow / in progress)
- Operational reading rule:
  - prioritize status of the latest commit on `main`
  - ignore older failed runs unless the latest commit fails in the same workflow

## GitHub Automation Baseline (active)

- `CI`
- `CodeQL`
- `Docs History Validation`
- `Dependabot`
- `Memory Guard`

These are considered the active baseline automations for the current phase.

## Git Push Capability (April 14, 2026)

- Local repo remote is now SSH-based (`git@github.com:thelaunchpadtlp/clonewatch.git`).
- SSH auth for this machine was validated successfully against GitHub.
- Operational implication:
  - Codex can execute `push origin` directly in this workspace when needed.
  - Continue using intentional commit scope and memory discipline before push.

## Default Assistant Git Flow (April 14, 2026)

- New default execution policy:
  - implement -> validate -> update memory (if applicable) -> commit -> push
- Auto-push is now default unless the user explicitly requests no push.
- Assistant should still pause for explicit confirmation when push risk is non-obvious.
- Policy recorded in:
  - `README.md`
  - `CONTRIBUTING.md`
  - `docs/decisions/git-operations.md`

## Actions Noise Reduction (April 14, 2026)

- Dependabot cadence was reduced from weekly to monthly.
- Open PR limit per ecosystem was reduced from 5 to 2.
- Batch grouping was enabled for both:
  - `github-actions`
  - `swift`
- Goal: reduce Actions queue noise and make failures easier to triage.

## CodeQL Triage Adjustment (April 14, 2026)

- CodeQL workflow was adjusted to skip runs when actor is `dependabot[bot]`.
- CodeQL concurrency was added (`cancel-in-progress: true`) per ref to avoid stale overlapping runs.
- Security posture kept:
  - CodeQL still runs on `main` pushes
  - CodeQL still runs on scheduled cadence
- Operational goal: preserve meaningful security signal while removing low-value noise from automated dependency PR traffic.

## Core Delivery 1-3 Integration (April 14, 2026)

- Copy phase now includes `rsync` dry-run estimation before execution:
  - estimates transferred files and bytes
  - keeps reinforcement jobs transparent and efficient
- Verification engine now respects selected verification mode:
  - `size-only` ignores metadata deltas
  - `metadata` flags metadata deltas (permissions, modified date, symlink target)
  - checksum comparison remains active only in checksum modes
- Runtime now passes `CloneJob.verificationMode` into verification compare logic.
- Test coverage expanded for:
  - incremental copy argument behavior
  - dry-run summary parsing
  - size-only vs metadata verification behavior

## Plan-Approval Memory Automation (April 14, 2026)

- User requirement adopted: every approved plan must trigger immediate memory update before implementation work.
- Integrated into project governance:
  - policy documented in `README.md`
  - policy documented in `CONTRIBUTING.md`
  - formal decision record added: `docs/decisions/plan-approval-memory-policy.md`
- Guardrail reinforcement:
  - `Memory Guard` now ignores Dependabot bot noise
  - `Memory Guard` also treats `docs/decisions/**` and `docs/plans/**` changes as memory-requiring changes

## Session Traceability Notes (April 14, 2026)

- Added policy for storing session metadata as operational trace data.
- Added registry entry with:
  - session id
  - codex deeplink
  - working directory
- Practical guidance:
  - session ids can change over time
  - keep canonical project memory in durable docs, not tied to one session id

## Execution Checkpoint (Pre-fix) (April 14, 2026)

- User requested token-efficient correction pass with memory update before and after execution.
- Active issue to solve:
  - failing test `runtimeEmitsProgressSnapshotsForDocumentOnlyRun`
  - failure source currently tied to SQLite import command path in ledger generation
- Execution target:
  - apply robust SQLite command fix
  - stabilize progress architecture changes already in-flight
  - restore full test green state

## Execution Checkpoint (Post-fix) (April 14, 2026)

- SQLite ledger generation was fixed robustly:
  - switched from brittle `.read` argument invocation to shell-safe SQLite import via redirected SQL file
- Progress architecture was integrated:
  - serializable run progress model (`RunPhase`, `RunProgressSnapshot`)
  - runtime progress timeline emission wired through execution phases
  - ledger now exports `run-progress.json` for future agent/API consumption
- Run UI foundation improved:
  - progress percent, phase timeline, didactic narrative card, concise log, and technical log disclosure
  - accessibility labels/values added on key progress controls
- Governance improvements landed:
  - `Memory Guard` ignores Dependabot actor noise
  - plan-approval memory-first policy documented and recorded
  - session traceability policy and session registry added
- Validation:
  - `swift test` passed (all tests green)

## macOS Ambition Intake (April 14, 2026)

- Large macOS/HIG/accessibility/ecosystem checklist was accepted as project input.
- Integrated approach chosen:
  - implement high-impact items now
  - keep remaining items as explicit `PENDING INTEGRAL` backlog (inside project docs, not lost)
- Added:
  - `docs/roadmap/macos-first-class-adoption.md`
  - `docs/decisions/macos-prioritization-framework.md`
- Actions interpretation reinforcement:
  - investigate latest `main` run first
  - treat older/bot noise as secondary unless latest mainline fails in the same workflow

## Inherent Records Automation (April 14, 2026)

- User requested roadmap + changelog updates become inherent project behavior.
- Implemented:
  - new `CHANGELOG.md`
  - new `Project Records Guard` workflow
  - decision record: `docs/decisions/records-automation-policy.md`
- Rule now enforced:
  - major changes must update at least roadmap or changelog
  - memory updates remain mandatory through Memory Guard

## Execution Checkpoint (Pre-implementation) (April 14, 2026)

- User approved implementation of a frugal but robust multi-agent coordination model.
- Mandatory first step completed: memory updated before any new implementation changes.
- Active implementation target:
  - install `CollabOps` governance and operational scripts
  - formalize `Single Writer` as default mode with explicit lock contract
  - harden GitHub workflows with a new `collab-guard`
  - reduce Actions noise and resolve the interrupted/stale Dependabot branch situation
- Delivery method:
  - compact, high-signal docs/contracts/protocol changes
  - strict checks (`swift build`, `swift test`, workflow sanity)
  - post-execution memory update and push

## Execution Checkpoint (Post-implementation) (April 14, 2026)

- `CollabOps` baseline implemented with `single-writer` as default:
  - protocol, capability matrix, recovery checklist
  - lock contract and schemas
  - session log + handoff model
  - SQLite collab evidence database and schema
  - operational scripts for begin/claim/record/handoff/release/recover
- GitHub hardening implemented:
  - new workflow: `Collab Guard`
  - existing guards expanded to include CollabOps-sensitive paths
  - CI noise reduced further with Dependabot actor filter + concurrency in CI
- Interrupted/noisy GitHub pending item resolved:
  - stale remote Dependabot branch `dependabot/github_actions/github-actions-batch-44aa17bcce` was deleted from origin
  - remote heads now show only `main`
- Validation status:
  - CollabOps self-test passed
  - shell syntax checks passed
  - JSON schema syntax checks passed
  - SQLite record counts confirm logging/handoff/lock events persisted
  - `swift build` passed
  - `swift test` passed (7/7)
