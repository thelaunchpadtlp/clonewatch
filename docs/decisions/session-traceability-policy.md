# Decision: Session Traceability Policy

Date: 2026-04-14

## Why this can be useful

Session metadata can help with:

- fast resume of prior work context
- audit trail of important design/implementation conversations
- reproducibility of decisions linked to specific working directories

## What to store

- session id (as reference only)
- deep link (for operator convenience)
- working directory
- short summary of what was decided in that session

## Stability expectations

- Session IDs can change across conversations/sessions.
- Deep links are convenience pointers, not permanent architectural identifiers.
- Do not build core product logic that depends on a specific session id.

## Usage rule

- Treat session metadata as operational trace notes.
- Keep source of truth in durable project docs (`clonewatch.md`, `docs/project-memory.md`, decision records), not in session ids.
