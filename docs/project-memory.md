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
