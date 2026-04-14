# Sesiones Importantes (Important Sessions)

Date created: 2026-04-14

---

## Purpose

This subsystem preserves records of important development sessions across all agents.

A "session" here means a meaningful conversation or working session between the user and an AI agent (Codex, Claude, ChatGPT, etc.) that produced decisions, implementations, or context relevant to the project.

This is NOT a log of every session. Only sessions that:
- produced major design decisions
- implemented significant features
- resolved important incidents
- contained context not captured elsewhere

---

## Why this exists

AI agents have context windows. When a session ends, its full context is lost.
The project already has `clonewatch.md` and `docs/project-memory.md` for operational summaries,
but those don't preserve the reasoning, the full decision chain, or the "why" behind choices.

This subsystem provides:
1. **Session records** — structured summaries of important sessions
2. **Raw session archives** — references to raw JSONL/export files (stored locally, not in git)
3. **Decision traces** — the key decisions made in each session and why

---

## Structure

```
docs/sessions/
  README.md              ← this file
  index.md               ← table of all recorded sessions
  schema/
    session-record.schema.json  ← JSON schema for session records
  records/
    <session-id>.md      ← one record per important session
```

Raw session files (JSONL exports) are stored locally at:
`/Users/piqui/Downloads/` or user-specified location.
They are NOT committed to git (too large: 60k-125k tokens each).
Session records contain references to their local paths.

---

## How to add a session record

1. Get the session export (JSONL from Codex, or session ID from Claude)
2. Create a new file: `docs/sessions/records/<session-id-slug>.md`
3. Use the schema in `docs/sessions/schema/session-record.schema.json` as guide
4. Add an entry to `docs/sessions/index.md`
5. Commit with `docs(sessions): add session record for <description>`

---

## Rules

- Session records are immutable once committed (append-only if corrections needed)
- Raw JSONL files must stay local (never commit files >1MB to this repo)
- Each record must link to its source file path (even if local-only)
- Decision records inside sessions should also appear in `docs/decisions/` when they are architectural
