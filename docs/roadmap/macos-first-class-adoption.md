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

## SPRINT A — UI/UX Reality Check (active, starting now)

### Sprint A Goals

The infrastructure phase is complete. Sprint A shifts focus to the user experience of the
actual shipped app. The output is a findings document, not new code.

1. **Build + test verification**: `swift build` clean, `swift test` 7/7 passing
2. **End-to-end wizard run**: Source → Destination → Plan → Run → Verify with a real disk; document every friction point
3. **Ledger inspection**: Verify SQLite ledger is written correctly at all three placement locations
4. **UX audit**: Document all points where the interface is confusing, incomplete, or not "Apple enough"

### Sprint A UI/UX Improvement Targets (identified from code review)

**Native macOS materials and visuals:**
- [ ] Replace `Color.white.opacity(0.45)` sidebar with `.ultraThinMaterial` (vibrancy, depth, system adaptation)
- [ ] Replace static `LinearGradient` background with adaptive system background that responds to Dark Mode and Tinted Mode
- [ ] Apply `.regularMaterial` to `CalloutCard` and `PhaseTimelineView` instead of manual opacity

**Navigation and structure:**
- [ ] Replace manual `HStack(spacing: 0) { sidebar, Divider(), mainPanel }` with `NavigationSplitView` for correct macOS sidebar semantics (resizable, collapsible, standard width)
- [ ] Add `Toolbar` with macOS-standard toolbar items (step navigation, cancel run button)
- [ ] Reduce minimum window width from 1080px to something closer to 860–900px; 1080 is too constraining on smaller screens

**Step indicators and icons (SF Symbols):**
- [ ] Replace plain `Circle()` step indicators with SF Symbols: `circle`, `circle.fill`, `checkmark.circle.fill`, `xmark.circle.fill` — system-scaled, accessibility-aware
- [ ] Add step-specific icon per wizard step (e.g. `externaldrive` for Source, `folder` for Destination, `list.clipboard` for Plan, `play.circle` for Run, `checkmark.seal` for Verify)

**Transitions and animations:**
- [ ] Add `.transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))` between wizard steps with `.animation(.spring(response: 0.35, dampingFraction: 0.8))`
- [ ] Animate phase timeline dots: transition from gray → orange → green with spring physics
- [ ] Animate `ProgressView` value changes with explicit animation
- [ ] Add completion animation when job finishes (brief celebratory visual in Verify step)

**Drag and drop:**
- [ ] Enable drag-and-drop of volumes/folders onto Source and Destination path fields using `.onDrop(of: [.fileURL], ...)` — the most "Mac" way to pick paths
- [ ] Accept drops from Finder sidebar (mounted volumes) and Desktop

**Keyboard and commands:**
- [ ] Add `Commands { ... }` with keyboard shortcuts: `Cmd+Enter` (Next/Run), `Cmd+[` (Back), `Cmd+R` (Run), `Cmd+W` (close with confirmation if running)
- [ ] Add `Settings { ... }` scene with `Cmd+,` for preferences

**Contextual polish:**
- [ ] Add `.help(...)` tooltip to every picker and button (native macOS hover tooltips)
- [ ] Animate `ProgressView` with `.progressViewStyle(.circular)` during indeterminate phases and `.linear` for percentile phases
- [ ] Show volume icon badge (disk image icon, external drive icon) when a real mounted volume is selected as source

**Accessibility upgrades:**
- [ ] Add `.accessibilityHint(...)` to all interactive elements
- [ ] Ensure all step navigation is fully keyboard-operable (Tab, Space, Return)
- [ ] Add `.accessibilityElement(children: .combine)` to SummaryPill cluster in Verify step
- [ ] Verify VoiceOver narrative reads wizard progress naturally ("Step 1 of 5: Choose the source")

**Settings scene (Preferences):**
- [ ] `Cmd+,` scene: verification mode default, post-action default, inventory depth default, sound/haptics on/off, reduced motion preference

**App icon and branding:**
- [ ] Design and ship a proper app icon (currently default Swift/Xcode icon)
- [ ] Consider a wristwatch + external drive mark — minimal, professional, memorable

**Menu bar:**
- [ ] Add standard macOS menu commands (File > New Job, Edit > Copy Path, Help > CloneWatch Help)
- [ ] Optional: Menu Bar Extra for quick status when a long job is running in the background

**macOS integration:**
- [ ] `NSOpenPanel` already used — add `allowedContentTypes: [.volume, .folder]` for cleaner filtering
- [ ] Use `NSWorkspace.shared.open(url)` to reveal ledger bundle in Finder from Verify step
- [ ] Add `NSSharingService` share button for the run report HTML

## NEXT (high-value near-term)

- [x] Gate A closure: GitHub Actions CI fully healthy (achieved 2026-04-14)
- [ ] Settings scene (`Cmd+,`) with:
  - launch-at-login toggle (if background mode is enabled)
  - sound/haptics toggles
  - accessibility options (reduced motion behavior)
- [ ] App Intents + basic Shortcuts actions for core jobs
- [ ] Notification pipeline for long runs (start/completion/actionable alerts)
- [ ] Security-scoped bookmarks for persistent folder permissions

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
