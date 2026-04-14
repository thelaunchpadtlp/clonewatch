# CloneWatch

CloneWatch is a macOS-first cloning, verification, and storage-migration project.

## What this repo contains

- A native `SwiftUI` app skeleton for `CloneWatch v2`
- A reusable `CloneWatchCore` module for preflight, copying, inventory, verification, and audit bundles
- A docs tool that preserves the original ChatGPT project history by extracting the provided PDFs into Markdown
- Legacy project memory and the earlier `scan_clone.py` script for historical reference

## Strategic docs

- `docs/roadmap/macos-first-class-adoption.md`: prioritized adoption map (Now / Next / Later / Pending integral)
- `docs/decisions/macos-prioritization-framework.md`: decision rule for high-impact feature intake
- `docs/collab/protocol.md`: multi-agent operating protocol with Single Writer as default
- `docs/collab/agent-capability-matrix.md`: practical role/risk matrix for external agentic apps
- `CHANGELOG.md`: detailed change history

## Current architecture

CloneWatch is being designed around five capability bands:

1. Clone
2. Verify
3. Document
4. Migrate
5. DiskOps

Important architectural rules:

- The GUI should not run fully as `root`
- Normal operations should run as the user whenever possible
- Privileged storage operations should move into a narrow helper later
- Full Disk Access must be detected and guided, not silently granted
- iCloud / File Provider locations must be treated as higher-risk paths

## Repo layout

- `Sources/CloneWatchApp`: macOS SwiftUI app
- `Sources/CloneWatchCore`: domain models and engines
- `Sources/CloneWatchDocsTool`: PDF extraction and transcript reconstruction tool
- `Tests/CloneWatchCoreTests`: basic automated tests
- `docs/`: architecture, memory, chat transcript, and reconstruction notes
- `scan_clone.py`: legacy script kept as project history

## Useful commands

```bash
swift build
swift test
swift run CloneWatchDocsTool
```

## GitHub workflow for beginners

The healthy loop is:

1. Make changes locally
2. Review them
3. Commit them with a clear message
4. Push them to GitHub
5. Open a Pull Request for bigger changes

Suggested branch strategy:

- `main`: stable baseline
- `feature/...`: new work
- `fix/...`: bug fixes
- `docs/...`: documentation-only changes

## GitHub automation in this repo

This repo now includes baseline GitHub automation:

- `CI`: builds and tests the project on pushes and pull requests
- `Docs History Validation`: reruns the chat-history extraction pipeline and fails if generated files were not committed
- `CodeQL`: scans the Swift codebase for security issues
- `CodeQL` runs are prioritized for `main` and scheduled scans; Dependabot-triggered runs are skipped to reduce low-value noise
- `Dependabot`: proposes batched monthly updates for GitHub Actions and Swift dependencies (limited concurrent PRs to reduce noise)
- `Memory Guard`: if architecture/runtime/automation files change, memory files must also be updated in the same PR/commit (`clonewatch.md` or `docs/project-memory.md`)
- `Project Records Guard`: major changes must update roadmap and/or changelog (`docs/roadmap/macos-first-class-adoption.md` or `CHANGELOG.md`)
- `Collab Guard`: critical changes must include session-trace evidence (`docs/collab/session-log.jsonl` and/or `docs/collab/handoffs/*`)

These automations are healthy because they protect quality and security without making uncontrolled changes to your code.

## Current status

This repo has been bootstrapped locally but may still need GitHub authentication on this Mac before `git push` works from Terminal.

## Codex Git Push Capability (local environment)

This development environment is now configured to push using SSH to:

- `git@github.com:thelaunchpadtlp/clonewatch.git`

Operational policy:

- Codex may execute `push origin` directly when the user requests it or when required to complete an agreed workflow.
- Pushes should stay scoped to reviewed changes and clear commit messages.
- This capability depends on local machine SSH configuration and can be rotated/revoked at any time from GitHub SSH keys.

Default execution policy (from now on):

- After implementing agreed changes and running relevant checks, Codex will push to `origin/main` automatically unless the user explicitly says not to push.
- If a push involves non-obvious risk (for example destructive behavior, major refactors, or unresolved failures), Codex should pause and request confirmation before pushing.
- When a plan is approved, memory update is mandatory as the first implementation step (`clonewatch.md` + `docs/project-memory.md`).

## Single Writer (for dummies, step by step)

Single Writer means only one active tool/agent edits the repo at a time.

Why this helps:

- avoids overwrite conflicts
- keeps history understandable
- makes handoff between apps reliable

Minimal command flow:

```bash
tools/collab/begin-session.sh --owner "Your Name" --agent-app "ChatGPT Desktop" --session-id "session-001"
swift build
swift test
tools/collab/record-step.sh --owner "Your Name" --agent-app "ChatGPT Desktop" --session-id "session-001" --event "VALIDATE" --message "Build and tests passed."
tools/collab/handoff.sh --owner "Your Name" --agent-app "ChatGPT Desktop" --session-id "session-001" --summary "Implemented scoped changes and validated."
tools/collab/release-lock.sh --owner "Your Name" --agent-app "ChatGPT Desktop" --session-id "session-001"
```

If the session was interrupted, use:

```bash
tools/collab/recover-interrupted-session.sh --owner "Your Name" --agent-app "ChatGPT Desktop" --session-id "session-002"
```
