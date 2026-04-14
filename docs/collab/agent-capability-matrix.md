# Agent Capability Matrix (Operational)

Date: 2026-04-14

This matrix is for safe project operations, not marketing claims. If any tool behavior changes, update this file and memory.

## Common rule for all tools

- all tools must follow `docs/collab/protocol.md`
- only one active writer session by default
- no tool may bypass lock + logging + handoff requirements

## Matrix

| Tool / App | Typical Strength | Typical Risk | CloneWatch Role |
|---|---|---|---|
| ChatGPT (desktop/web) | Fast architectural and coding iteration | Context truncation if logs/memory are skipped | Full writer (with lock protocol) |
| Claude Desktop / Claude Code | Strong coding and refactor support | Can drift if handoff discipline is weak | Full writer (with lock protocol) |
| Perplexity | Research and cross-source synthesis | Can provide stale or non-authoritative implementation assumptions | Research assistant + optional doc writer |
| Google Antigravity | Agentic development workflows | Workflow assumptions may differ from local project controls | Writer only when lock + local guards are respected |
| Manus Desktop ("My Computer") | Computer-use and operational automation | Higher risk of accidental broad actions on host machine | Restricted writer; prefer docs/ops tasks unless explicitly scoped |

## Enablement checklist before giving write access to any new tool

1. confirm operator identity mapping (`owner`, `agent_app`, `session_id`).
2. run `tools/collab/begin-session.sh`.
3. verify lock acquired.
4. verify expected checks can run locally.
5. verify handoff file can be created.

If any check fails, the tool runs in read-only/research mode.

