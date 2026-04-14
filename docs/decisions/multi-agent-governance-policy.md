# Decision: Multi-Agent Governance (Single Writer Default)

Date: 2026-04-14

## Decision

CloneWatch adopts a hybrid multi-agent model with strict defaults:

- `single-writer` is default.
- `direct-main` is allowed only with full safeguards.
- `parallel-branches` remains available for broad/high-risk work.

## Why

- protects repository integrity while keeping velocity high
- supports handoffs between different agentic apps without context loss
- minimizes merge conflicts and accidental overwrite behavior

## Mandatory controls

- lock lease file (`.clonewatch/agent-lock.json`)
- append-only session trace (`docs/collab/session-log.jsonl`)
- structured handoff on close (`docs/collab/handoffs/*`)
- memory and records governance checks remain mandatory

