# Claude Handoff Template

Use this as reference when writing handoff notes.
The handoff script fills most fields automatically; this template is for the summary content.

---

## Template for summary argument in handoff.sh

```
Done: <one-line description of what was completed>.
Pending: <one-line description of what is next>.
Warnings: <any risks, blockers, or things to watch>.
Next agent: Codex | Claude | Either.
Next recommended commands: swift build, swift test.
```

---

## Example

```bash
tools/collab/handoff.sh \
  --owner "The Launch Pad - TLP" \
  --agent-app "Claude Code" \
  --session-id "claude-20260414-180000" \
  --summary "Done: created CLAUDE.md, docs/sessions, docs/temp subsystems. Pending: CI fix (GitHub Actions quota blocker), clonewatch.md full restructure. Warnings: GitHub Actions still failing (steps:[]), make repo public to fix. Next agent: Codex."
```

---

## What must be in the handoff (checklist)

- [ ] What was done (concrete, not vague)
- [ ] What was NOT done (defer list with reason)
- [ ] Any active risks or warnings
- [ ] State of CI / tests (pass/fail)
- [ ] Which agent should go next
- [ ] Any tasks left in docs/temp/ for next agent
