# External Inbox

This folder is the official intake channel for **externos** (external apps/agents/developers/AI systems).

Each incoming task is one JSON file:

- path: `docs/collab/external-inbox/<task_id>.json`
- schema: `docs/schemas/external-task-request.schema.json`

## Required states

- `NEW`
- `CLAIMED`
- `BLOCKED`
- `DONE`
- `REJECTED`

## Minimal flow

1. externo drops task JSON in inbox (or uses `tools/collab/external-new-task.sh`)
2. writer claims with valid lock (`external-claim-task.sh`)
3. writer updates status in outbox (`external-update-task.sh`)
4. all events are mirrored into:
   - `docs/collab/session-log.jsonl`
   - `docs/collab/collab.sqlite`

## Important

Inbox task files are immutable request records. Status progression is communicated through outbox event files.
