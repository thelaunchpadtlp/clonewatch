# Codex Commit and PR Instructions (Copy/Paste)

Use this content in Codex Git settings.

## Commit instructions

```text
Use Conventional Commits with explicit scope:
<type>(<scope>): <short imperative summary>

Allowed types: feat, fix, refactor, docs, test, chore, ci, perf, security.
Scope must be one of: core, ui, ledger, inventory, verify, collabops, docs, ci, github, roadmap, changelog.

Body is REQUIRED for all non-trivial commits and must include:
- Why: business/user reason in plain language.
- What: key implementation changes (high signal only).
- Validation: exact checks run (build/test/scripts) and result.
- Collab trace: agent_app, session_id, lock_owner, handoff path.
- Records updated: memory/roadmap/changelog paths (or explicit “not required” justification).

Rules:
- No secrets/tokens/credentials in code, logs, commits, or PR text.
- If Sources/, Package.swift, .github/workflows/, docs/architecture, docs/collab/, docs/schemas/, tools/collab/ changed, memory update is mandatory.
- If major behavior/process changed, changelog or roadmap update is mandatory.
- Keep commits atomic and reversible. No mixed unrelated changes.
```

## PR instructions

```text
Title format:
<type>(<scope>): <short outcome-focused summary>

PR description must contain these sections in order:
1) Objective
2) Context / Problem
3) Changes implemented
4) Risks and mitigations
5) Validation performed (commands + outcomes)
6) CollabOps trace (session id, lock owner, handoff evidence)
7) Records updated (memory, roadmap, changelog)
8) Rollback plan
9) Pending follow-ups (if any)

Required checkboxes:
- [ ] No secrets exposed
- [ ] Memory updated (or justified not needed)
- [ ] Roadmap/changelog updated (or justified not needed)
- [ ] Tests/build executed and results included
- [ ] Single Writer protocol respected (or exception documented)

Multi-agent policy:
- PR must explicitly state whether change came from Single Writer or parallel branch path.
- If parallel, include merge/conflict strategy and ownership boundaries.
```
