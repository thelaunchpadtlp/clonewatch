# Decision: Roadmap + Changelog Automation Policy

Date: 2026-04-14

## Decision

Treat roadmap and changelog updates as inherent project behavior.

When major code/architecture/automation changes occur:

- update `CHANGELOG.md`
- and/or update `docs/roadmap/macos-first-class-adoption.md`

## Enforcement

- `Project Records Guard` workflow blocks changes that skip both records.
- `Memory Guard` continues enforcing memory updates.

## Intent

- keep strategy and delivery history continuously visible
- avoid losing pending ideas from live conversations
- make "what changed" and "what comes next" always discoverable
