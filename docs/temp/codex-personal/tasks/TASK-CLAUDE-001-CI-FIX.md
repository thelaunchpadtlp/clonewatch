# TASK-CLAUDE-001: Fix GitHub Actions CI

- Date: 2026-04-14
- From: Claude Code (session `6e5936df`)
- Priority: HIGH (blocks all CI guards)
- Status: PARTIALLY DONE — see update below
- Depends on: USER ACTION (see billing note)

---

## ⚠️ ROOT CAUSE CORRECTION (updated by Claude Code, same session)

**Previous diagnosis was wrong.** The original TASK file said the cause was
"GitHub Actions minutes quota exhausted for private repo." This was incorrect.

**Actual root cause (confirmed via `gh run view`):**

```
The job was not started because recent account payments have failed or
your spending limit needs to be increased. Please check the 'Billing & plans'
section in your settings.
```

This is a **billing/payment issue at the GitHub account level**, not a minutes quota.
Making the repo public may help for Actions (public repos get free minutes),
but the payment failure is a separate account-level problem.

### What has been done since original task was written

1. ✅ User made the repo public (screenshot confirmed).
2. ✅ Claude attempted to push an empty commit to trigger CI — **push was rejected**
   because the main branch has a ruleset ("Protect main") requiring 4 status checks
   to pass before pushing directly to main: CI, CodeQL, Docs History Validation, Memory Guard.
3. ✅ A new CodeQL run auto-triggered after repo went public (was "in_progress" at last check).

### What still needs to happen

---

## Step 1 — USER action: Verify GitHub billing

1. Go to `https://github.com/settings/billing` (or org billing page)
2. Check for failed payments or spending limit issues
3. Resolve any outstanding payment or increase spending limit
4. Confirm account is in good standing

---

## Step 2 — Codex: Create a PR to trigger CI

Since direct push to main is blocked by the branch ruleset, CI must be triggered
via a Pull Request. Create a PR from any branch (or the existing `claude/ecstatic-noether`
branch) to main.

```bash
cd /Users/Shared/Pruebas/CloneWatch

# Option A: Use the existing worktree branch
git push origin claude/ecstatic-noether
gh pr create \
  --base main \
  --head claude/ecstatic-noether \
  --title "ci: trigger CI verification after billing fix and repo visibility change" \
  --body "$(cat <<'BODY'
## Purpose

Trigger CI to verify all workflows pass after:
1. Repository visibility changed from private to public
2. GitHub billing issue resolved

## What changed

No code changes — this PR exists to run status checks.

## Expected result

All 4 required checks pass: CI, CodeQL, Docs History Validation, Memory Guard.

Collab trace: agent_app=ChatGPT-Codex
Records updated: not required (CI verification only)
BODY
)"
```

---

## Step 3 — Codex: Monitor CI and check results

```bash
# List recent runs
gh run list --repo thelaunchpadtlp/clonewatch --limit 10

# Watch specific run
gh run watch $(gh run list --repo thelaunchpadtlp/clonewatch --limit 1 --json databaseId --jq '.[0].databaseId')

# View failures
gh run view $(gh run list --repo thelaunchpadtlp/clonewatch --limit 1 --json databaseId --jq '.[0].databaseId') --log-failed
```

---

## Step 4 — Codex: If CI passes, update incident record

Edit `docs/github/actions-root-cause-incident.md`:
- Change `Status: Open` → `Status: Resolved`
- Add a "Resolution" section:

```markdown
## Resolution

Date resolved: 2026-04-14
Action: Changed repository visibility to public; resolved GitHub billing issue.
Root cause confirmed: GitHub account payment failure (NOT private repo minutes exhaustion
as originally diagnosed). The billing error message from gh run view was:
"The job was not started because recent account payments have failed or your spending
limit needs to be increased."
Resolution authors: User (billing fix) + ChatGPT-Codex (CI verification)
```

---

## Step 5 — Codex: If CI passes, merge PR

```bash
# Merge the PR (squash merge for clean history)
gh pr merge --squash --delete-branch \
  --subject "ci: verify CI passes after public repo + billing fix" \
  --body "Collab trace: agent_app=ChatGPT-Codex"
```

---

## Step 6 — Codex: Update external task and memory

```bash
cd /Users/Shared/Pruebas/CloneWatch

# Mark external task done
tools/collab/external-update-task.sh \
  --task-id "EXT-ACTIONS-ROOTCAUSE-001" \
  --owner "The Launch Pad - TLP" \
  --agent-app "ChatGPT-Codex" \
  --session-id "<your-session-id>" \
  --status "DONE" \
  --message "Resolved: billing issue fixed, repo made public, all CI workflows pass."
```

Append to `clonewatch.md`:

```
Operational memory update (April 14, 2026 - GitHub Actions CI resolved)

- GitHub Actions CI was failing on all workflows.
- Root cause: GitHub account payment failure / spending limit issue (NOT minutes quota).
- Original diagnosis (private repo minutes) was incorrect — corrected after inspecting
  gh run view annotation which showed the actual billing error message.
- Solution: User resolved billing, repo made public, CI verified via PR.
- All five workflows now pass: CI, CodeQL, Memory Guard, Project Records Guard, Collab Guard.
- Gate A exit criteria satisfied.
```

Append to `docs/project-memory.md`:

```markdown
## CI Blocker Resolved (April 14, 2026)

- GitHub Actions restored after fixing account billing and making repo public.
- Root cause: GitHub account payment failure (original minutes-exhaustion diagnosis was wrong).
- All five workflows now pass.
- Gate A is now fully closed.
```

Commit:
```bash
git add docs/github/actions-root-cause-incident.md clonewatch.md docs/project-memory.md \
  docs/collab/external-outbox/ docs/collab/session-log.jsonl docs/collab/collab.sqlite
git commit -m "fix(ci): resolve GitHub Actions failure after billing fix and public repo

Why: all workflows were failing due to GitHub account payment issue (not minutes quota).
What: billing resolved by user, repo made public, CI verified passing via PR.
Validation: gh run list shows all workflows green.
Collab trace: agent_app=ChatGPT-Codex
Records updated: clonewatch.md, docs/project-memory.md, actions-root-cause-incident.md"

git push origin main
```

---

## Definition of done

- [ ] GitHub billing issue resolved (user action)
- [ ] CI, CodeQL, Memory Guard, Project Records Guard, Collab Guard all pass on PR
- [ ] PR merged to main
- [ ] `docs/github/actions-root-cause-incident.md` marked Resolved (with corrected root cause)
- [ ] External task `EXT-ACTIONS-ROOTCAUSE-001` marked DONE
- [ ] Memory updated (clonewatch.md + project-memory.md)
- [ ] Changes pushed to origin/main
