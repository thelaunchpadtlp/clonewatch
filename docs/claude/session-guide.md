# Claude Session Guide — Step-by-Step

Date: 2026-04-14

This is the detailed operational guide. CLAUDE.md is the quick reference.
Read this fully the first time; after that CLAUDE.md is enough.

---

## A. Starting a new session (full writer)

### Step 1 — Orient yourself (5 min)

```bash
cd /Users/Shared/Pruebas/CloneWatch

# Read current state
cat docs/collab/current-state.md

# Read last handoff
cat docs/collab/handoffs/$(ls -t docs/collab/handoffs/ | head -1)

# Check lock
python3 -c "
import json, time
try:
    d = json.load(open('.clonewatch/agent-lock.json'))
    exp = d.get('lease_expires_at_epoch', 0)
    now = int(time.time())
    if now > exp:
        print(f'LOCK EXPIRED (by {now-exp}s). Safe to reclaim.')
    else:
        print(f'LOCK ACTIVE — owner={d[\"owner\"]}, app={d[\"agent_app\"]}, expires in {exp-now}s')
except FileNotFoundError:
    print('NO LOCK — workspace is free')
"

# Check git
git fetch origin && git log --oneline -5 && git status -sb
```

### Step 2 — Claim the lock

```bash
SESSION_ID="claude-$(date +%Y%m%d-%H%M%S)"
tools/collab/begin-session.sh \
  --owner "The Launch Pad - TLP" \
  --agent-app "Claude Code" \
  --session-id "$SESSION_ID" \
  --mode "single-writer" \
  --ttl-minutes 90
# SAVE SESSION_ID — you'll need it for all subsequent calls
```

### Step 3 — Do work

- Use Bash/Read/Edit/Write tools as usual
- Prefer small, scoped commits over large batches
- Log milestones with record-step.sh

### Step 4 — Validate before pushing

```bash
cd /Users/Shared/Pruebas/CloneWatch
swift build 2>&1 | tail -10
swift test 2>&1 | tail -15
```

If tests fail, fix before pushing. Never push red tests.

### Step 5 — Update memory (mandatory if sources/architecture changed)

```bash
# Edit clonewatch.md — append new entry at the bottom
# Edit docs/project-memory.md — append new checkpoint
```

### Step 6 — Commit

```bash
git add -p  # or specific files
git commit -m "$(cat <<'EOF'
type(scope): short summary

Why: user/business reason
What: key changes
Validation: swift build OK, swift test OK (N/N passed)
Collab trace: agent_app=Claude Code, session_id=$SESSION_ID
Records updated: clonewatch.md, docs/project-memory.md
EOF
)"
```

### Step 7 — Push

```bash
git push origin main
# Verify push succeeded
git log --oneline -3
```

### Step 8 — Handoff and release

```bash
tools/collab/handoff.sh \
  --owner "The Launch Pad - TLP" \
  --agent-app "Claude Code" \
  --session-id "$SESSION_ID" \
  --summary "Brief: what done + what pending + any warnings"

# Update current-state.md
# nano docs/collab/current-state.md  (or Edit tool)

tools/collab/release-lock.sh \
  --owner "The Launch Pad - TLP" \
  --agent-app "Claude Code" \
  --session-id "$SESSION_ID"
```

---

## B. Starting a session as externo (read-only / analysis mode)

When Codex or another agent holds an active lock:

1. Read everything freely (no lock needed)
2. Do NOT run begin-session.sh
3. Leave plans: `docs/temp/claude-personal/plans/PLAN-NNN-topic.md`
4. Leave Codex tasks: `docs/temp/codex-personal/tasks/TASK-NNN-topic.md`
5. For formal external tasks: `tools/collab/external-new-task.sh ...`
6. Document your analysis in `docs/temp/claude-personal/notes/`

---

## C. Recovery from interrupted session

```bash
cd /Users/Shared/Pruebas/CloneWatch

# Check the lock
cat .clonewatch/agent-lock.json

# Check if expired
EXPIRES=$(python3 -c "import json; d=json.load(open('.clonewatch/agent-lock.json')); print(d['lease_expires_at_epoch'])")
NOW=$(date +%s)
echo "Expires at $EXPIRES, now is $NOW, diff=$((EXPIRES - NOW))"
# If negative → expired → safe to recover

NEW_ID="claude-$(date +%Y%m%d-%H%M%S)-recovery"
tools/collab/recover-interrupted-session.sh \
  --owner "The Launch Pad - TLP" \
  --agent-app "Claude Code" \
  --session-id "$NEW_ID"

# Re-run checks
git fetch origin && git status -sb
swift build 2>&1 | tail -5
swift test 2>&1 | tail -5
```

---

## D. Leaving tasks for Codex

Create a file in `docs/temp/codex-personal/tasks/TASK-NNN-slug.md`:

```markdown
# TASK-NNN: Task Title

- Date: YYYY-MM-DD
- From: Claude Code
- Priority: high | medium | low
- Status: PENDING

## Objective
What needs to be done and why.

## Exact commands to run

\`\`\`bash
# Step 1
command here

# Step 2
command here
\`\`\`

## Files to create/edit
- `path/to/file.md`: description of change

## Definition of done
- [ ] criterion 1
- [ ] criterion 2

## Notes / Warnings
Any gotchas or things to watch out for.
```

---

## E. Memory update template

Append to `clonewatch.md`:

```markdown
Operational memory update (April 14, 2026 - <topic>)

- <what changed>
- <what is pending>
- <anything to ignore or not worry about>
```

Append to `docs/project-memory.md`:

```markdown
## Execution Checkpoint (<Pre|Post>-<topic>) (April 14, 2026)

- <key facts>
- Validation: <test results>
```
