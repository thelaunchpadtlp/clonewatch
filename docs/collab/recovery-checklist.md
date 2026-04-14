# Recovery Checklist (Interrupted Session / Usage Limit)

1. Check `.clonewatch/agent-lock.json`.
2. If lock is expired, record a `RECOVERY_START` event.
3. Reclaim lock with a new `session_id`.
4. Read last entries in `docs/collab/session-log.jsonl`.
5. Read latest file in `docs/collab/handoffs/`.
6. Check `docs/collab/external-inbox/` and `docs/collab/external-outbox/` for delegated tasks in `CLAIMED` or `BLOCKED`.
7. Re-run `git status -sb`, `git fetch`, and `swift test` before new edits.
8. Continue from last confirmed state, then log `RECOVERY_COMPLETE`.

Never continue silently after interruption.
