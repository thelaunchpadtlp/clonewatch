# Temporales por Externo

Date created: 2026-04-14

---

## Purpose

This directory provides isolated, private workspaces for each external agent (externo) working on the CloneWatch project.

Each agent gets their own folder for:
- Temporary notes, observations, analyses
- Draft plans (before they become official decisions)
- Artifacts not ready for the main project
- Private calculations or research

---

## Important: collaborative mode is the default

Using `docs/temp/` is the **exception**, not the rule.

The preferred mode is full collaboration — shared documents, open protocols, collective memory.
Use your temp folder only when:
- You are doing interim analysis not yet ready to share
- You are drafting a plan before proposing it formally
- Another agent is active and you need a private scratchpad
- You are exploring ideas that may not be implemented

---

## Directory structure

```
docs/temp/
  README.md              ← this file (policy and rules)
  _inventory.md          ← what exists in all temp folders (updated by each agent)
  _event-log.md          ← what happened in this subsystem (append-only)
  codex-personal/        ← Codex (personal account)
  codex-team/            ← Codex (team account)
  chatgpt-personal/      ← ChatGPT (personal account)
  chatgpt-team/          ← ChatGPT (team account)
  antigravity/           ← Google Antigravity
  vertex-ai/             ← Google Vertex AI
  gemini/                ← Google Gemini
  cursor/                ← Cursor
  lovable/               ← Lovable
  replit/                ← Replit
  claude-personal/       ← Claude (personal account) ← this is Claude Code's folder
  claude-team/           ← Claude (team account)
  perplexity-personal/   ← Perplexity (personal account)
  perplexity-team/       ← Perplexity (team account)
  manus-personal/        ← Manus (personal account)
  manus-team/            ← Manus (team account)
```

Each folder contains:
- `.profile.json` — agent identity and capabilities (see schema below)
- `README.md` — workspace rules for that specific agent
- Agent-specific files (notes, plans, tasks, etc.)

---

## Rules

1. **Privacy by policy**: Do not read another agent's temp folder without explicit permission.
   (Git cannot enforce this — it's a collaborative honor system.)

2. **No lock required**: You may write to YOUR temp folder without claiming the Single Writer lock.
   Temp folders are isolated by design.

3. **No product code**: Temp folders are for notes/plans/artifacts only.
   Any code that affects the product belongs in the main source tree (with proper lock protocol).

4. **No secrets**: Do not put API keys, tokens, credentials, or personal data here.
   This directory is tracked in git and visible to all.

5. **Cleanup**: Archive or delete old content from your temp folder when it's no longer needed.
   There is no automatic cleanup.

6. **Promote to main**: When a plan or document in temp is ready for the project, move it to the
   appropriate location in `docs/` and commit it normally.

7. **Update inventory**: When you add something significant, update `_inventory.md`.

8. **Event log**: When you start or finish using your workspace, append to `_event-log.md`.

---

## CI exclusions

This directory is excluded from Memory Guard, Collab Guard, and Project Records Guard.
Changes here do not trigger those CI checks.
(See `.github/workflows/` for the exclude patterns.)

---

## .profile.json schema

```json
{
  "agent_id": "string (unique identifier for this agent)",
  "agent_app": "string (display name)",
  "account_type": "personal | team",
  "capabilities": ["read", "write", "bash", "web", "file-system"],
  "collab_role": "full-writer | externo-analyst | read-only",
  "owner_mapping": "string (which human operator uses this agent)"
}
```

---

## Tasks from other agents

Agents may leave tasks for each other in sub-folders:
- `codex-personal/tasks/` — tasks left for Codex by other agents
- `claude-personal/tasks/` — tasks left for Claude by other agents

Task files are named `TASK-<ORIGIN>-<NNN>-<slug>.md`.
Example: `TASK-CLAUDE-001-ci-fix.md` means "task created by Claude, task #001, about CI fix".
