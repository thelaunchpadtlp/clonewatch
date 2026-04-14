# CloneWatch macOS First-Class Adoption Roadmap

Date: 2026-04-14

This roadmap converts the long checklist into an execution model that is ambitious but token/time efficient.

V1 release gating companion:

- `docs/roadmap/v1-productized-gates.md`

Default intake rule:

- when conversation logic implies a meaningful capability addition, it is added here by default (even if not explicitly requested as "update roadmap")

## North Star

Build CloneWatch as a first-class macOS utility for non-technical users:

- clear guided cloning flow
- strong verification and documentary evidence
- native system behavior
- accessibility-first operation
- architecture reusable by UI, automation, and future agent/API adapters

## NOW (active implementation scope)

### Product & UX

- [x] Wizard flow with progressive steps (source, destination, plan, run, verify)
- [x] Plain-language status messaging for non-technical users
- [x] Didactic run explanations and phase timeline
- [x] Reinforcement model ("copy only what changed")

### Core Architecture

- [x] `CloneWatchCore` as source of truth
- [x] Phase-based run progress contract (`RunPhase`, `RunProgressSnapshot`, `Codable`)
- [x] Decoupled runtime orchestration + UI consumption
- [x] Durable evidence bundle (JSON, Markdown, HTML, SQLite, run progress JSON)

### Accessibility Baseline

- [x] Accessibility labels/values on critical run controls
- [x] Color-independent state cues in timeline (text + indicator)
- [ ] Full keyboard audit of the complete wizard
- [ ] Accessibility Inspector audit checklist pass

### Security & Delivery Baseline

- [x] CI + CodeQL + docs validation + memory guardrails
- [x] Policy-driven memory governance
- [x] Multi-agent CollabOps baseline (single-writer lock + session log + handoff protocol)
- [x] `Collab Guard` workflow for critical-change traceability
- [x] External delegation channels (`external-inbox` / `external-outbox`) with session + SQLite evidence
- [x] GitHub auth/access policy and diagnostics script (`diagnose-github-actions.sh`)
- [ ] macOS signing/notarization pipeline scaffolding
- [ ] Hardened runtime validation in CI

## NEXT (high-value near-term)

- [ ] Settings scene (`Cmd+,`) with:
  - launch-at-login toggle (if background mode is enabled)
  - sound/haptics toggles
  - accessibility options (reduced motion behavior)
- [ ] App Intents + basic Shortcuts actions for core jobs
- [ ] Notification pipeline for long runs (start/completion/actionable alerts)
- [ ] Security-scoped bookmarks for persistent folder permissions
- [ ] Gate A closure: GitHub Actions infra constraints resolved (minutes/policy/runners) with latest `main` green

## LATER (strategic platform integrations)

- [ ] Menu Bar extra for quick run status and shortcuts
- [ ] Core Spotlight indexing for ledger/job lookup
- [ ] Finder Sync / Quick Look (only if file-centric workflow justifies it)
- [ ] XPC helper boundary for privileged operations
- [ ] Distribution hardening: full notarization + release automation

## PENDING INTEGRAL (tracked, not dropped)

- [ ] Expanded accessibility:
  - full keyboard traversal guarantee
  - VoiceOver narrative for full workflow
  - reduced motion and high-contrast audit gates
- [ ] Personality layer:
  - friendly micro-copy states
  - optional celebratory completion feedback
  - optional lightweight sound/haptic feedback with off switch
- [ ] Ecosystem expansion:
  - widgets
  - deeper Finder integrations
  - plugin model evaluation
- [ ] Universal links / URL schemes for external orchestration
- [ ] Advanced multi-agent orchestration dashboard (cross-tool visibility and metrics)
- [ ] Optional automation bridge so externos can open tasks through connectors/APIs directly into `external-inbox`
- [ ] "Temporales por Externo" subsystem:
  - per-externo temporary workspaces
  - inventory and event logs
  - strict isolation + anti-contamination safeguards
  - explicit "exceptional use" policy (collaboration-first remains default)
- [ ] "Help Solve or Help Solve Better" subsystem:
  - shared serious-problem registry for all externos
  - lightweight contracts, flows, and evidence standards
  - automation-first intake/update so reporting is low-friction
  - cross-externo collaboration loops to improve/fix solutions
- [ ] Reliability hardening for interrupted streams (`stream disconnected before completion`) with runbook + safeguards
- [ ] Enforcement model so externos must read/acknowledge project standards before write operations

## Explicit deprioritization for current product stage

- [ ] Metal/OpenGL/OpenCL-specific optimization tracks (not primary for current I/O-heavy utility profile)
