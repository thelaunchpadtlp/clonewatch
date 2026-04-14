# Decision: External Delegation Channel as First-Class Project Mechanism

Date: 2026-04-14

## Decision

Adopt a first-class delegation mechanism for **externos** (external apps/agents/developers/AI systems):

- intake: `docs/collab/external-inbox/`
- responses: `docs/collab/external-outbox/`
- lifecycle states: `NEW`, `CLAIMED`, `BLOCKED`, `DONE`, `REJECTED`

## Why

- lower token/cost overhead by reusing pre-scoped tasks from external tools
- preserve traceability in multi-agent execution
- avoid lock bypass and hidden side channels

## Consequences

- all externally delegated work must produce:
  - outbox event files
  - session log events
  - SQLite evidence rows
- only active lock owner can claim/execute delegated tasks
