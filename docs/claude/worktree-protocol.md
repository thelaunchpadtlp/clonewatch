# Claude Worktree Protocol

Date: 2026-04-14

---

## What a worktree is

A git worktree is a second checkout of the same repo at a different path.
It lets Claude work on an isolated branch without affecting main.

```
/Users/Shared/Pruebas/CloneWatch/          ← main checkout (Codex writes here)
/Users/Shared/Pruebas/CloneWatch/.claude/worktrees/ecstatic-noether/  ← Claude's worktree
```

Both share the same `.git/` directory. They see each other's commits once pushed.

---

## When to use a worktree

USE worktree when:
- Making Swift code changes (Sources/, Tests/, Package.swift)
- Making broad changes (>5 files)
- Codex might be starting a session soon
- You want to experiment without risking main

WRITE DIRECTLY TO MAIN when:
- Docs-only changes (docs/, CLAUDE.md, *.md)
- Lock is held and changes are scoped
- Single file, obvious change

---

## Creating a new worktree

```bash
cd /Users/Shared/Pruebas/CloneWatch

# Convention: claude/YYYYMMDD-description
BRANCH="claude/$(date +%Y%m%d)-my-feature"
WPATH=".claude/worktrees/$(date +%Y%m%d)-my-feature"

git worktree add "$WPATH" -b "$BRANCH"
cd "$WPATH"
# ... do work here ...
```

---

## Current active worktrees

| Branch | Path | Status |
|---|---|---|
| `claude/ecstatic-noether` | `.claude/worktrees/ecstatic-noether` | Clean, synced with main |

---

## Merging a worktree branch into main

Only merge after:
1. `swift build` passes in the worktree
2. `swift test` passes in the worktree
3. Lock is claimed on main

```bash
# From the main checkout (not the worktree)
cd /Users/Shared/Pruebas/CloneWatch
git merge claude/my-feature --no-ff -m "merge(scope): integrate claude/my-feature"
git push origin main
```

---

## Cleaning up a worktree

```bash
cd /Users/Shared/Pruebas/CloneWatch
git worktree remove .claude/worktrees/my-feature
git branch -d claude/my-feature
```

---

## Worktree and the lock

The lock (`.clonewatch/agent-lock.json`) is shared between the main checkout and all worktrees.
Claiming the lock from within a worktree is valid.
The lock is repo-wide — worktrees don't have their own locks.

---

## The `.claude/` directory

The `.claude/` directory in the repo root is Claude Code's local state:
- `.claude/worktrees/` — active worktrees
- `.claude/settings.json` — Claude Code settings

**This directory is intentionally gitignored** (or should be).
It contains local tool state, not shared project state.

Codex noted a `.claude/` directory appeared after Claude Desktop interaction.
This is expected and normal. Do not commit it to the repo unless explicitly decided.
