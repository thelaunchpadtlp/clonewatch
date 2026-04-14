# CloneWatch CollabOps Protocol (Single Writer Default)

Date: 2026-04-14

## Why this exists

Multiple agentic tools can work on this project over time. To avoid conflicts, CloneWatch uses a strict but simple protocol:

- one active writer by default (`Single Writer`)
- durable logs for every meaningful step
- reproducible handoffs between sessions and tools
- structured delegation for **externos** (external apps/agents/developers/AI systems)

## Operating modes

1. `single-writer` (default): one writer session at a time.
2. `direct-main`: allowed only with all gates green.
3. `parallel-branches`: optional for high-risk or broad changes.

If there is any doubt, use `single-writer`.

## State machine

`BEGIN -> CLAIM_LOCK -> SYNC -> WORK -> VALIDATE -> RECORD -> PUSH -> HANDOFF -> RELEASE`

Each state must be logged in `docs/collab/session-log.jsonl`.

For externally delegated work, use:

`EXTERNAL_TASK_NEW -> CLAIMED -> (INFO)* -> DONE | BLOCKED | REJECTED`

## Single Writer play-by-play

1. BEGIN
- register `owner`, `agent_app`, `session_id`, `mode`.
- read current git state and current lock.

2. CLAIM_LOCK
- create `.clonewatch/agent-lock.json`.
- mandatory lock fields:
  - `owner`
  - `agent_app`
  - `session_id`
  - `started_at`
  - `lease_expires_at`
  - `base_commit`
  - `mode`
- if lock is active and not expired, stop.

3. SYNC
- `git fetch`.
- verify local branch is synchronized.
- if sync fails, stop before editing.

4. WORK
- perform scoped changes.
- log meaningful milestones.

5. VALIDATE
- run required checks (`swift build`, `swift test`, plus targeted checks).
- if checks fail, no push.

6. RECORD
- update memory when applicable.
- update roadmap/changelog when applicable.
- record end-state in session log.

7. PUSH
- push to `main` only if all safeguards pass.
- otherwise use branch fallback.

8. HANDOFF
- write a structured handoff file in `docs/collab/handoffs/`.

9. RELEASE
- release lock.

## Recovery when a session is interrupted

If service stops or usage limit interrupts execution:

1. inspect lock age and owner.
2. if lock is stale (expired), write a recovery event.
3. reclaim lock with explicit trace record.
4. continue from last logged step.

Do not force-replace an active lock without a recorded incident.

## Required artifacts per active session

- one or more JSONL events in `docs/collab/session-log.jsonl`
- lock lifecycle trace (`claim` and `release`, or recovery trace)
- one handoff note in `docs/collab/handoffs/`

## External delegation protocol (mandatory)

### Official naming

- **externos**: any external app/agent/developer/AI system outside the active writer session.

### Channels

- inbox: `docs/collab/external-inbox/`
- outbox: `docs/collab/external-outbox/`

### Rules

1. externos can create tasks in inbox (`NEW`) but cannot bypass lock rules.
2. only active lock owner may claim and execute (`CLAIMED`).
3. every status update must emit outbox event + JSONL event + SQLite evidence.
4. terminal task status must be one of:
   - `DONE`
   - `BLOCKED`
   - `REJECTED`

### Recommended commands

```bash
tools/collab/external-new-task.sh ...
tools/collab/external-claim-task.sh ...
tools/collab/external-update-task.sh ...
```
