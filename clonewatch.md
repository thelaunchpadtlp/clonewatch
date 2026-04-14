CloneWatch Project Memory (Updated)

Overview

The CloneWatch project grew out of a desire to verify and track the progress of a large disk-to-disk clone. The conversation originally focused on cloning the contents of volume 1D3A to another volume 1D3B and ensuring the clone was complete before deleting the source drive. Over time, the discussion expanded first into a Python-based verification tool, and then into a much broader macOS-native platform for cloning, reinforcement, verification, storage migration, disk-topology awareness, and durable documentary evidence.

This document summarises the history and context of the project across sessions, including the functional requirements and improvements requested, as a reference for future development.

Original Goals

1. Cloning verification: Ensure that directory 1D3A (source) is fully replicated in 1D3B (target) before deleting the source.
2. Cross-platform accessibility: Reports should be viewable on macOS and iPhone. Initially the user suggested storing outputs in a Google Drive folder synced with their iPhone.
3. Minimal user involvement: The user wants to run a single command in Terminal to execute the whole process, including creating the script, selecting paths, and generating reports.
4. Future-proof reports: Include both HTML (for human viewing) and JSON (for programmatic use) outputs. Provide optional `.webloc` file to open reports via local web server.

Recovered Historical Features From The PDFs

- Remote-friendly viewing: reports should be viewable on macOS, iPhone, Google Drive, or a local web server.
- HTML and JSON dual output: human-readable and machine-readable evidence should always coexist.
- One-step setup bias: the user repeatedly preferred a single command or a highly guided flow with as little manual work as possible.
- zsh-safe prompts: avoid `read -p` and other shell assumptions that break in the user's environment.
- Progress and logs: the tool should be transparent while scanning or copying, not silent.
- Difference intelligence: list missing, extra, and changed items, not just summary counts.
- Safety decision support: the app should help answer whether it is safe to keep, archive, merge, or delete the source.
- Versioning and memory: `README`, `project.md`, and `clonewatch.md` should preserve context between sessions.
- Legacy migration help: the old discussion already touched scanning config files and scripts for hard-coded legacy paths such as `/Volumes/1D3`.

Current Reframing Of The Product

CloneWatch v2 is no longer just a clone verifier. It is being redesigned as a macOS-first migration and storage orchestration platform with five capability bands:

1. Clone
2. Verify
3. Document
4. Migrate
5. DiskOps

DiskOps is itself split conceptually into:

- Read-only topology inspection
- Safe operations
- Destructive operations

The app should understand workflows such as:

- folder to folder
- folder to volume
- volume to folder
- volume to volume
- reinforcement of an already existing clone
- verify-only or document-only passes

Important New Architectural Constraints

- The GUI should not run entirely as `root`.
- Normal work should run as the logged-in user whenever possible.
- The app should ask for what it can ask for directly, especially file-system access through native macOS pickers.
- Full Disk Access cannot be silently granted by the app itself; CloneWatch must detect the need, explain it, and guide the user.
- Future destructive operations such as deleting a cloned volume, resizing partitions, or changing APFS topology should run through a narrow privileged helper, not a fully privileged GUI.
- The app must be aware of APFS concepts such as devices, partition maps, containers, volumes, and snapshots.
- The app must also be aware of iCloud Drive and File Provider behavior.

iCloud / File Provider Considerations

If the source or destination lives in iCloud Drive, shared iCloud folders, or another File Provider-backed location, CloneWatch must treat that as a higher-risk environment because:

- files may exist as placeholders and not be fully downloaded
- sync can still be in progress while the clone runs
- shared folders can change from another device or person
- strict verification becomes harder if the tree is mutating during the run

Because of this, CloneWatch should:

- detect iCloud-backed paths during preflight
- warn about hydration and sync state
- avoid pretending that cloud-backed paths behave exactly like normal local disks
- separate a practical clone from a high-confidence forensic clone

Root / Protected Path Considerations

The user expressed interest in letting CloneWatch work at very high privilege levels, including potentially touching root-owned paths and performing Disk Utility-like operations. The refined design direction is:

- CloneWatch should support privileged workflows where appropriate
- but it should not assume that root alone bypasses every modern macOS protection
- sealed system areas and SIP-protected regions must be treated as special cases
- using `/` directly as a clone root should be blocked or heavily constrained in v2

Evidence Philosophy

The project now aims to generate a durable audit bundle for every important operation. That bundle should help answer:

- what existed before
- what was copied
- what changed
- what permissions were needed
- what risks were known during the run
- whether the original should be kept, archived, merged, or deleted

The bundle should be stored centrally and mirrored into source and destination whenever safe.

Evolution of the Tool

First script iteration (basic CloneWatch)

The earliest script scanned two directories (`ROOT_A` and `ROOT_B`), built an index of files/directories with sizes, compared them, calculated overall copy progress, and generated HTML/JSON reports. It summarised counts of items only in A, only in B, same size, or different size. The HTML report used dark-themed styling and summarised the first 30 paths. It included a section for `.app-externalizer` folder analysis. Outputs were saved into the user's Google Drive folder so they could view the report on their iPhone.

Pain points and requests

Over multiple sessions the user requested numerous improvements:

- Dynamic installation: Instead of manually creating the script file, the user wanted to paste one command into Terminal that asked for the destination directory, created the folder with `sudo`, wrote the script, gave it execute permission, and ran it. The script should ask the user for the base directories or read from variables.
- Error with zsh: The user's shell is `zsh`. Using `read -p` caused `no coprocess` errors. A fix required using `read` without `-p` and using `printf` or `echo` for prompts.
- Progress feedback: Running the script over large directories took a long time and provided no feedback. The user wanted progress bars and status messages indicating what was being scanned and how many items were processed.
- Logs and debugging: Add logging to a file and optionally a verbose debug mode that prints more details to the terminal. This will help identify why counts differ between A and B.
- Differences analysis: The script should produce a separate section listing discrepancies: paths present in A but not B, paths present in B but not A, or files with different sizes. It should compute the size difference. The user wants to know why `Entradas en A` and `Entradas en B` differ (for example `3497804` vs `3497802`) and whether the difference affects total storage.
- Safety confirmation: Include logic to warn if there are still discrepancies or missing items, confirming whether it is safe to erase the source volume.
- Script versioning: Each time the script is regenerated, the previous version should be archived with a timestamp (for example `scan_clone_20260414_2200.py`). The script should also generate a `README.md` or `project.md` describing the tool, how to use it, and a log of past runs.
- Memory persistence: Because the chat history is long, a separate memory file should record the history, tasks, decisions, and improvements. The user wants the assistant to maintain this memory (for example `clonewatch.md`) and update it when new features or steps are added. This helps overcome ChatGPT's context limitations.

PDF transcripts

The user provided several PDF files (`APP`, `AAPP`, `AAAPP`, `AAAAPP`) containing transcriptions of earlier chat sessions. They requested that the assistant read these carefully to reconstruct the full history and ensure no requested feature is missed. Due to time and context constraints the assistant did not parse every line but noted that the PDFs capture detailed instructions, additional improvements (for example using progress bars, rewriting prompts, customizing output), and conversation context.

Current status (April 14, 2026)

1. Script execution: The script successfully scanned `1D3A` and `1D3B` and produced reports. For example, on April 14, 2026 it reported:
   - `Entradas en A: 3 497 804`
   - `Entradas en B: 3 497 802`
   - The HTML and JSON reports were saved to the Google Drive path as `report.html` and `report.json`.
   - The script prints a completion message.
2. Remaining issues:
   - The script still lacks a progress bar and verbose logging.
   - There is no difference analysis beyond counts; missing/different paths are not listed in a separate section.
   - When `read -p` was used, `zsh` produced an error; the prompt logic must be replaced with `read` and `printf`.
   - Versioning and `README` generation are not implemented.
   - The script runs sequentially and cannot stop previous versions automatically.

Recommendations for the next script version

To fulfil the user's latest requests, the next script should:

1. Interactive but simple setup: Use a shell one-liner that:
   - Asks for the destination directory using `read` and `echo` (zsh-compatible).
   - Creates the directory with `sudo mkdir -p "$DIR"`.
   - Backs up the existing `scan_clone.py` if present (rename with timestamp).
   - Writes the updated Python script to `$DIR/scan_clone.py` via `tee` or `cat <<'PY'` here-document.
   - Creates or updates a `README.md` describing the project and logging runs.
   - Gives execute permissions and runs the script.
2. Progress reporting:
   - Count the total number of entries (files and directories) in both trees before scanning, then update progress after each item or per directory.
   - Use `tqdm` if available, or implement a simple text progress bar using carriage returns to update the same line.
   - Write progress to a log file and optionally show it on screen.
3. Logging and debug mode:
   - Use Python's `logging` module to record events.
   - Create `scan_clone.log` in the output directory.
   - Let the user toggle a `DEBUG` variable to enable more detailed logs.
4. Difference report:
   - After comparing indexes, generate an additional HTML/JSON table listing paths only in A, only in B, and those with size differences.
   - Include total size difference per category.
   - Summarise whether the differences are negligible or significant.
   - Provide a safety message: if there are any discrepancies, indicate that the clone may be incomplete; otherwise, confirm it is safe to delete the source.
5. Version management:
   - Before writing a new `scan_clone.py`, back up the existing one with a timestamp.
   - Maintain a `project.md` or `README.md` in the CloneWatch directory, documenting changes, run history, and instructions.
6. Memory file:
   - Save this memory summary as `clonewatch.md` in the project folder so it can be referred to by future sessions.
   - Update it as the project evolves.

Contents of this memory file

This memory (`clonewatch.md`) summarises:

- The origin and evolution of the CloneWatch project.
- Major user requirements and improvements requested.
- Observations from running the script (counts, report generation).
- Outstanding issues and recommended enhancements.

It is meant to be stored alongside the scripts and reports to provide historical context for future development and to address the user's concern about ChatGPT's limited context.

Operational update (April 14, 2026) - GitHub, synchronization, and CI

- Repository alignment: local `main` and `origin/main` were brought back into a healthy synchronized flow after push/pull confusion in GitHub Desktop.
- Large PDF limitation handled: raw transcript PDFs are larger than GitHub's 100 MB per-file limit, so they are kept as local artifacts and referenced through:
  - `docs/chat-history/raw-pdfs/README.local.md`
  - `docs/chat-history/raw-pdfs.manifest.tsv`
- Historical text still preserved in repo: extracted markdown files under `docs/chat-history/extracted/` and the canonical transcript remain tracked.
- Automation baseline added for collaboration quality:
  - CI workflow
  - CodeQL workflow
  - Docs-history validation workflow
  - Dependabot configuration
  - contribution and security policy files
- Stability fixes applied:
  - resolved accidental `README.md` merge-conflict markers
  - updated docs-history workflow so CI does not fail when raw PDFs are intentionally local-only
- Actions interpretation guidance for non-technical use:
  - green check = passed
  - yellow circle = queued or running
  - red X = failed and needs intervention
  - many Dependabot entries are expected background noise, not necessarily urgent blockers
- Decision for project memory strategy:
  - before context compaction, always write a short dated memory entry with what changed, what is pending, and what is safe to ignore

Memory Guard promoted to central product governance (April 14, 2026)

- The team decision is to treat memory continuity as a first-class feature of CloneWatch, not merely an assistant reminder.
- Repository-level enforcement was added via GitHub Actions workflow `Memory Guard`.
- Enforcement rule:
  - when architecture/runtime/automation surfaces are changed, memory must be updated in the same commit/PR
  - accepted memory targets are `clonewatch.md` and `docs/project-memory.md`
- Practical outcome:
  - fewer context-loss regressions
  - better handoff quality across sessions
  - clearer auditability of why design decisions changed over time

Operational memory update (April 14, 2026 - Actions and GitHub automation status)

- Current run focus is commit `f59a166` (`Institutionalize Memory Guard as core project feature`).
- For that commit:
  - `CI` is green (passed).
  - `Memory Guard` is green (passed).
  - `CodeQL` is still running (yellow / in progress at the time of this memory update).
- Team rule confirmed: ignore old red runs from prior commits and unrelated Dependabot noise when validating the latest mainline health.
- Branch protection status:
  - ruleset for `main` was created in GitHub settings
  - warning observed: in the current private-org plan, enforcement is limited unless upgraded
  - mitigation adopted: keep ruleset as future-ready config and continue operational discipline with required green checks before merge decisions
- GitHub automation baseline considered complete for this phase:
  - `CI`
  - `CodeQL`
  - `Docs History Validation`
  - `Dependabot`
  - `Memory Guard`

Operational memory update (April 14, 2026 - SSH push capability enabled)

- User completed GitHub SSH key registration for this machine.
- Repository remote was switched from HTTPS to SSH:
  - `git@github.com:thelaunchpadtlp/clonewatch.git`
- SSH authentication test succeeded (`Hi thelaunchpadtlp! You've successfully authenticated...`).
- Project-level decision:
  - Codex can now perform `push origin` directly from terminal in this workspace when requested or when needed to complete agreed flows.
  - pushes remain subject to normal safety discipline (clear commit scope, readable commit messages, and memory updates when required).

Operational memory update (April 14, 2026 - default auto-push workflow)

- User requested that push behavior become default and explicit in project policy.
- Policy adopted:
  - after agreed implementation + relevant validation + memory update, Codex should commit and run `push origin` automatically by default
  - only skip auto-push if user explicitly asks not to push
  - if risk is non-obvious (destructive ops, unresolved failures, uncertain blast radius), Codex pauses for explicit confirmation
- Policy documentation added to:
  - `README.md`
  - `CONTRIBUTING.md`
  - `docs/decisions/git-operations.md`

Operational memory update (April 14, 2026 - Actions triage adjustment)

- User requested repairs/actions based on noisy GitHub Actions dashboard.
- Triage outcome:
  - latest mainline runs are the priority signal
  - old red runs and unrelated Dependabot failures should not block current development decisions
- Concrete repo action applied:
  - Dependabot reduced from weekly to monthly
  - open PR cap lowered from 5 to 2 per ecosystem
  - update grouping enabled for `github-actions` and `swift`
- Intended effect:
  - fewer concurrent automation runs
  - clearer CI signal
  - lower operational noise during active development

Operational memory update (April 14, 2026 - CodeQL signal cleanup)

- Based on Actions screenshots, repeated CodeQL failures were mostly linked to older runs and automated Dependabot PR activity.
- Workflow adjustment applied:
  - skip CodeQL job when actor is `dependabot[bot]`
  - add per-ref concurrency with cancel-in-progress to avoid stale overlapping analyses
- Security intent preserved:
  - keep CodeQL on mainline and scheduled runs
  - reduce noisy non-actionable failures in dashboard view

Operational memory update (April 14, 2026 - integrated 1-3 implementation pass)

- Efficiency-focused implementation pass completed across copy + verification + runtime flow.
- CopyEngine upgrade:
  - added pre-copy rsync dry-run estimation
  - logs estimated transferred files/bytes before actual copy
  - keeps reinforcement workflows transparent and aligned with "copy only what changed"
- Verification upgrade:
  - comparison now respects selected verification mode
  - `size-only` avoids metadata warnings
  - `metadata` includes permissions/modified-at/symlink-target checks
  - checksum differences are evaluated only in checksum modes
- Runtime wiring:
  - `CloneWatchRuntime` now passes `job.verificationMode` into verification compare call
- Reliability:
  - new tests added for dry-run parsing, incremental argument building, and verification-mode behavior
  - test suite passed after changes

Operational memory update (April 14, 2026 - plan-approval memory first)

- User requested memory updates to happen automatically every time a plan is approved.
- Project decision accepted and institutionalized:
  - memory update is now the first required step after plan approval
  - applies before implementation changes start
- Governance updates:
  - policy documented in `README.md` and `CONTRIBUTING.md`
  - decision file added: `docs/decisions/plan-approval-memory-policy.md`
  - `Memory Guard` expanded to include `docs/decisions/**` and `docs/plans/**` as memory-sensitive paths
  - `Memory Guard` now ignores Dependabot actor noise to keep signal focused on human changes

Operational memory update (April 14, 2026 - session metadata traceability)

- User proposed storing session id, deeplink, and working directory inside project records.
- Decision adopted with constraints:
  - session metadata is useful for operational continuity and resume flows
  - session metadata must remain auxiliary (not a hard dependency for product behavior)
  - session ids/deeplinks may change between sessions
- Added:
  - `docs/decisions/session-traceability-policy.md`
  - `docs/decisions/session-registry.md` with the provided session reference

Operational memory update (April 14, 2026 - pre-execution checkpoint)

- User requested an efficient corrective pass with memory update before and after execution.
- Immediate technical blocker identified:
  - failing runtime test around ledger SQLite generation (`sqlite3` invocation shape).
- Planned immediate action:
  - correct SQLite import invocation in a robust way
  - finish progress-flow integration already in-flight
  - run full tests, then update post-execution memory and push to GitHub

Operational memory update (April 14, 2026 - post-execution completion)

- Execution goals were completed in one efficient pass:
  - robust fix for failing SQLite ledger test path
  - progress orchestration integrated end-to-end (phases, timeline, percent, event stream)
  - run UI upgraded for didactic visibility and basic accessibility
  - machine-consumable progress artifact added (`run-progress.json`)
  - Memory Guard noise reduction and policy governance updates integrated
- Test status after completion:
  - full `swift test` suite passed
- Delivery discipline satisfied:
  - memory updated before execution and after execution
  - pending changes are ready for commit/push

Operational memory update (April 14, 2026 - macOS ambition capture and integral pending)

- User requested ambitious incorporation of broad macOS design/architecture/accessibility guidance.
- Project response chosen:
  - absorb the checklist into a structured roadmap
  - implement high-impact sections now
  - keep the rest as explicit, first-class pending items in project records
- Artifacts added:
  - `docs/roadmap/macos-first-class-adoption.md`
  - `docs/decisions/macos-prioritization-framework.md`
- Operating principle reinforced:
  - prioritize latest mainline CI signal for debugging
  - prevent older/bot run noise from derailing active delivery

Operational memory update (April 14, 2026 - roadmap/changelog as inherent automation)

- User requested that roadmap updates and changelog updates become default project behavior.
- Implemented as project-level governance and automation:
  - added `CHANGELOG.md`
  - added workflow `.github/workflows/project-records-guard.yml`
  - added decision record `docs/decisions/records-automation-policy.md`
- Default behavior now:
  - when major changes happen, strategy and change records are updated by default
  - if not updated, CI guard fails
