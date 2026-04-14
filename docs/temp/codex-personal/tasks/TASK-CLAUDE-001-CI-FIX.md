# TASK-CLAUDE-001: Fix GitHub Actions CI

- Date: 2026-04-14
- From: Claude Code (session `6e5936df`)
- Priority: HIGH (blocks all CI guards)
- Status: PENDING
- Depends on: USER ACTION (make repo public first)

---

## Objective

GitHub Actions is failing on all workflows with `steps: []` (pre-step exit).
Root cause: minutes quota exhausted for private repo on free GitHub plan.
Fix: make the repo public → unlimited CI minutes.

---

## Step 1 — USER action (cannot be done by Codex or Claude)

The user must manually do this in GitHub web:
1. Go to `https://github.com/thelaunchpadtlp/clonewatch`
2. Settings → General → scroll to Danger Zone → "Change repository visibility"
3. Click "Make public"
4. Type `thelaunchpadtlp/clonewatch` to confirm
5. Tell Codex "repo is now public, run CI trigger"

---

## Step 2 — Codex: trigger CI after repo goes public

After user confirms repo is public, run this from the repo root:

```bash
cd /Users/Shared/Pruebas/CloneWatch

# Trigger CI with an empty commit
git commit --allow-empty -m "ci: trigger CI verification after repo visibility change

Why: GitHub Actions was failing pre-step due to exhausted private-repo minutes.
Making repo public resolves the quota constraint.
Validation: this commit triggers all workflows to verify they now run correctly.
Collab trace: agent_app=ChatGPT-Codex
Records updated: not required (operational trigger only)"

git push origin main
```

---

## Step 3 — Codex: verify CI is now green

```bash
# Wait ~2 minutes then check
gh run list --repo thelaunchpadtlp/clonewatch --limit 5

# Check latest run in detail
gh run view $(gh run list --repo thelaunchpadtlp/clonewatch --limit 1 --json databaseId --jq '.[0].databaseId') --log
```

Expected outcome: all workflows pass (CI, CodeQL, Memory Guard, Project Records Guard, Collab Guard).

---

## Step 4 — Codex: update the incident record

Edit `docs/github/actions-root-cause-incident.md`:
- Change `Status: Open` → `Status: Resolved`
- Add a "Resolution" section at the bottom:

```markdown
## Resolution

Date resolved: 2026-04-14
Action: Changed repository visibility from private to public.
Root cause confirmed: GitHub Actions free-tier minutes exhaustion for private repos.
Resolution author: [Codex or Claude]
```

---

## Step 5 — Codex: update external task to DONE

```bash
cd /Users/Shared/Pruebas/CloneWatch
tools/collab/external-update-task.sh \
  --task-id "EXT-ACTIONS-ROOTCAUSE-001" \
  --owner "The Launch Pad - TLP" \
  --agent-app "ChatGPT-Codex" \
  --session-id "$(cat .clonewatch/agent-lock.json | python3 -c 'import json,sys; print(json.load(sys.stdin)[\"session_id\"])')" \
  --status "DONE" \
  --message "Resolved: repo made public, CI quota constraint removed. All workflows now pass."
```

---

## Step 6 — Codex: update memory and push

After CI is confirmed green, append to `clonewatch.md`:

```
Operational memory update (April 14, 2026 - GitHub Actions CI resolved)

- GitHub Actions CI was failing with steps:[] on all workflows.
- Root cause: private repo on free GitHub account had exhausted Actions minutes quota.
- Solution: repository visibility changed from private to public.
- All workflows now pass: CI, CodeQL, Memory Guard, Project Records Guard, Collab Guard.
- Gate A exit criteria satisfied.
```

And append to `docs/project-memory.md`:

```
## CI Blocker Resolved (April 14, 2026)

- GitHub Actions restored after making repo public.
- Root cause: free-tier minutes exhaustion (private repo quota).
- All five workflows now pass.
- Gate A is now fully closed.
```

Commit and push:
```bash
git add docs/github/actions-root-cause-incident.md clonewatch.md docs/project-memory.md \
  docs/collab/external-outbox/ docs/collab/session-log.jsonl docs/collab/collab.sqlite
git commit -m "fix(ci): resolve GitHub Actions pre-step failure by making repo public

Why: all workflows were failing with steps:[] due to private-repo minutes quota exhaustion.
What: changed repo visibility to public, verified all five workflows pass.
Validation: gh run list shows all workflows green.
Collab trace: agent_app=ChatGPT-Codex
Records updated: clonewatch.md, docs/project-memory.md, actions-root-cause-incident.md"

git push origin main
```

---

## Definition of done

- [ ] Repo is public on GitHub
- [ ] CI, CodeQL, Memory Guard, Project Records Guard, Collab Guard all pass
- [ ] `docs/github/actions-root-cause-incident.md` marked Resolved
- [ ] External task `EXT-ACTIONS-ROOTCAUSE-001` marked DONE
- [ ] Memory updated (clonewatch.md + project-memory.md)
- [ ] Changes pushed to origin/main
