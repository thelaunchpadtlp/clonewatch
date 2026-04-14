# External Outbox

This folder is the official response channel back to **externos**.

Each status/progress/completion update is an event JSON:

- path: `docs/collab/external-outbox/<task_id>--<timestamp>--<EVENT>.json`
- schema: `docs/schemas/external-task-event.schema.json`

## Event types

- `NEW`
- `CLAIMED`
- `BLOCKED`
- `DONE`
- `REJECTED`
- `INFO`

## Why this exists

- cheap coordination across multiple tools
- no hidden state
- audit-ready trace that can be parsed by humans or automation
