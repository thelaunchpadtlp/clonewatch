# TASK-CLAUDE-001: Fix GitHub Actions CI

- Date: 2026-04-14
- From: Claude Code (session `6e5936df`)
- Priority: HIGH (blocks all CI guards)
- Status: MOSTLY RESOLVED — Codex follow-up in progress
- Depends on: Codex follow-up only

---

## Root cause timeline (corrected and extended)

### Incident A — original repo-wide failure

**Previous diagnosis was wrong.** The original task said the cause was
"private repo minutes quota exhausted." That was incorrect.

**Actual observed annotation (confirmed via `gh run view`):**

```
The job was not started because recent account payments have failed or
your spending limit needs to be increased. Please check the 'Billing & plans'
section in your settings.
```

This was a **billing/payment issue at the GitHub account level**, not a minutes quota.
After the repository became public, normal workflow execution resumed.

### Incident B — follow-up CodeQL / merge gating issue

Once CI started running again, a second issue appeared:

- CodeQL failed because **GitHub default Code Scanning setup** and the custom
  `codeql.yml` workflow were both active.
- PR #4 then became merge-blocked because the ruleset requires
  `Docs History Validation`, but that workflow only ran when certain paths changed.

### What has been done

1. ✅ Repo is public, and Actions are executing normally again.
2. ✅ GitHub default Code Scanning setup was disabled with:
   `gh api -X PATCH repos/thelaunchpadtlp/clonewatch/code-scanning/default-setup -f state='not-configured'`
3. ✅ CodeQL reran successfully on PR #4.
4. ⏳ Remaining fix: make `Docs History Validation` always emit a required check on PRs to `main`.

### What still needs to happen

---

## Step 1 — Codex: land the follow-up workflow fix on PR #4

Update:
- `.github/workflows/docs-history.yml` so PRs to `main` always emit `Docs History Validation`
- `.github/workflows/codeql.yml` so custom CodeQL uses `@v4` and explicit `swift build`
- `.gitignore` to ignore `.claude/`

Then push the branch and let PR #4 rerun.

---

## Step 2 — Codex: monitor PR #4 checks

```bash
# List recent runs
gh run list --repo thelaunchpadtlp/clonewatch --limit 10

# Watch specific run
gh run watch $(gh run list --repo thelaunchpadtlp/clonewatch --limit 1 --json databaseId --jq '.[0].databaseId')

# View failures
gh run view $(gh run list --repo thelaunchpadtlp/clonewatch --limit 1 --json databaseId --jq '.[0].databaseId') --log-failed
```

---

## Step 3 — Codex: if PR #4 is green, update incident record

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

## Step 4 — Codex: if PR #4 is green, merge PR

```bash
# Merge the PR (squash merge for clean history)
gh pr merge 4 --squash --delete-branch
```

---

## Step 5 — Codex: update external task and memory

```bash
cd /Users/Shared/Pruebas/CloneWatch

# Mark external task done
tools/collab/external-update-task.sh \
  --task-id "EXT-ACTIONS-ROOTCAUSE-001" \
  --owner "The Launch Pad - TLP" \
  --agent-app "ChatGPT-Codex" \
  --session-id "<your-session-id>" \
  --status "DONE" \
  --message "Resolved in two stages: repo visibility restored workflow execution; CodeQL default setup disabled; Docs History Validation now always reports required status on PRs."
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

- [x] GitHub billing/private-repo execution blocker mitigated
- [ ] CI, CodeQL, Memory Guard, Project Records Guard, Docs History Validation all pass on PR
- [ ] PR merged to main
- [ ] `docs/github/actions-root-cause-incident.md` marked Resolved (with corrected root cause)
- [ ] External task `EXT-ACTIONS-ROOTCAUSE-001` marked DONE
- [ ] Memory updated (clonewatch.md + project-memory.md)
- [ ] Changes pushed to origin/main
