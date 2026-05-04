# clonewatch — Agent Workflow Contract
Version: 1.0 | Updated: 2026-05-04
Status: Part of TLP Grand Unification (Phase 4 — GitHub Singularity)

## Entry Point
1. Read CLAUDE.md (if present)
2. Read HANDOFF.md (if present) — VERIFY claims before acting
3. Read this file
4. Read https://github.com/thelaunchpadtlp/universe-infrastructure/blob/main/SINGULARITY_PLAN.md

## Stack
Swift / SwiftUI — macOS-first cloning, verification, and migration application. CloneWatchCore as shared library target. Multi-agent collaboration system with lock protocol, session harvesting, and CI guards. Wave 4 complete.

## Agent Roles
- **Orchestrator (Claude Code):** Architecture decisions, multi-file changes, planning
- **Executor (Codex):** Single-file implementations, refactors, code generation
- **Reviewer (Gemini):** PR review, test coverage, security audit
- **Auditor:** Companion to every non-trivial agent run

## Active Plans
| Plan | Location | Status |
|------|----------|--------|
| Grand Unification — GitHub Singularity | [SINGULARITY_PLAN.md](https://github.com/thelaunchpadtlp/universe-infrastructure/blob/main/SINGULARITY_PLAN.md#phase-4-github-singularity) | PENDING — awaiting Phase 3 (GCP) |

## Coding Standards
- Swift 6 strict concurrency throughout
- SwiftUI for all UI; AppKit only for file system and dock integration
- CloneWatchCore as independent Swift Package target (no UI dependencies)
- Multi-agent lock protocol: check `.agent-lock` file before making changes
- SwiftLint enforced; zero warnings on CI
- Session harvesting: agents must write session summaries to `.sessions/`
- No force-unwraps; comprehensive error handling with typed errors

## Deploy Protocol
1. `swift build` — verify all targets (app + CloneWatchCore) build
2. `swift test` — run full test suite
3. Xcode for macOS app archiving and notarization
4. Direct distribution or Mac App Store (check HANDOFF.md for current channel)
5. Push to `main` triggers GitHub Actions CI (lock guard + build + test)
6. Verify: `gh run list --repo thelaunchpadtlp/clonewatch --limit 3`

## Verification
- All changes pushed to main trigger CI
- Check CI status: `gh run list --repo thelaunchpadtlp/clonewatch --limit 3`
