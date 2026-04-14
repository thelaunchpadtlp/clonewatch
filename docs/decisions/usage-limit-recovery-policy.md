# Decision: Usage-Limit / Interrupted Session Recovery

Date: 2026-04-14

## Decision

Interrupted runs (service cuts, usage limit, local crash) must follow a mandatory recovery sequence:

1. inspect lock
2. detect active vs stale lease
3. record recovery start event
4. recover or reclaim lock with traceability
5. resume only after sync and validation
6. record recovery completion event

## Why

- prevents silent lock stealing
- preserves operational continuity
- keeps troubleshooting evidence durable

## Required reference

Use `docs/collab/recovery-checklist.md` every time recovery mode is activated.

