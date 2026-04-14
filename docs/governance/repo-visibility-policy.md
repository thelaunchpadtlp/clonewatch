# Repository Visibility Policy

**File:** `docs/governance/repo-visibility-policy.md`
**Owner:** The Launch Pad - TLP
**Created:** 2026-04-14 (Claude Code session `6e5936df`)
**Last updated:** 2026-04-14

---

## Purpose

This document governs when and how the GitHub repository
`thelaunchpadtlp/clonewatch` may be toggled between **public** and **private**.
It is binding for all agents (Claude, Codex, ChatGPT, humans) operating in the
project. No visibility change may occur without following this protocol and
appending an entry to the [Decision Log](#decision-log) below.

---

## Institutional Principles

### P1 — Default: Public

The repository is public by default. Public visibility is the **operative
state** for this project. It enables:
- Free GitHub Actions minutes (unlimited for public repos)
- CodeQL, Dependabot, and security scanning at no cost
- External auditor access without invitation overhead

### P2 — Privacy Is Valued

The owner (The Launch Pad - TLP) is privacy-conscious and low-profile. Public
visibility is **operational**, not promotional. Do not treat the repo as a
marketing surface. Do not add social badges, stars calls-to-action, or
contributor solicitations.

### P3 — Proprietary IP Is Protected

The LICENSE file explicitly states All Rights Reserved. Public visibility does
**not** grant any license to copy, fork, or use the code. The two are
independent: a repo can be publicly visible and fully proprietary.

### P4 — Agents Do Not Toggle Unilaterally

No agent may change visibility without one of the conditions in the
[Authorized Triggers](#authorized-triggers) section being met. An agent that
wishes to toggle must:
1. Verify the trigger condition is satisfied.
2. Append a Decision Log entry **before** executing the toggle.
3. Execute the toggle.
4. Confirm the result and update the entry status.

### P5 — Revert Bias

If there is any doubt, keep the repo **public**. Private visibility triggers
billing for Actions and blocks CI. The cost of going private is higher than
the cost of staying public.

### P6 — Audit Trail Is Mandatory

Every visibility change, in either direction, must be logged in this file with
the exact reason, agent, session ID, and timestamp. This log is the source of
truth for any future compliance or security review.

---

## Authorized Triggers

### → Switch to Private

| ID | Trigger | Notes |
|----|---------|-------|
| T-PVT-1 | Sensitive credentials or IP accidentally committed to repo | Immediate lockdown; rewrite history; re-open only after scrub is confirmed |
| T-PVT-2 | Owner explicit instruction to go private | Owner may instruct any agent verbally or in writing; agent must confirm before toggling |
| T-PVT-3 | Pre-acquisition / fundraising due diligence period | Toggle back to public after diligence window closes |
| T-PVT-4 | Security vulnerability disclosed under embargo | Keep private until patch is merged and CVE published |

### → Switch to Public

| ID | Trigger | Notes |
|----|---------|-------|
| T-PUB-1 | CI / Actions are broken and private repo is the cause | This is the original trigger; billing/minutes issues require public status |
| T-PUB-2 | After private-trigger condition has been resolved | Re-open once the incident that caused T-PVT-* is fully resolved |
| T-PUB-3 | Owner explicit instruction to go public | |

---

## Toggle Procedure

### Making Private

```bash
# Step 1 — log the decision (append to Decision Log in this file first)
# Step 2 — execute the toggle
gh api -X PATCH repos/thelaunchpadtlp/clonewatch -f private=true

# Step 3 — verify
gh repo view thelaunchpadtlp/clonewatch --json visibility --jq '.visibility'
# Expected: "PRIVATE"

# Step 4 — update Decision Log entry with "confirmed" status
```

### Making Public

```bash
# Step 1 — log the decision (append to Decision Log in this file first)
# Step 2 — execute the toggle
gh api -X PATCH repos/thelaunchpadtlp/clonewatch -f private=false

# Step 3 — verify
gh repo view thelaunchpadtlp/clonewatch --json visibility --jq '.visibility'
# Expected: "PUBLIC"

# Step 4 — update Decision Log entry with "confirmed" status
```

---

## Impact Reference

| Dimension | Public | Private |
|-----------|--------|---------|
| GitHub Actions minutes | Unlimited (free) | Limited by plan; billing may block runs |
| CodeQL | Included | Requires Advanced Security ($) |
| Dependabot alerts | Free | Free |
| Secret scanning | Free | Free |
| Forking | Allowed (but no license = no rights) | Not allowed by outsiders |
| Discoverability | Indexed by GitHub search | Hidden |
| CI risk | Low | High if billing lapses |

---

## Decision Log

Each entry follows this schema:

```
### [YYYY-MM-DD] [DIRECTION] — [TRIGGER-ID]

- Date/Time: YYYY-MM-DD HH:MM UTC
- Direction: PUBLIC → PRIVATE | PRIVATE → PUBLIC
- Trigger: [T-PVT-* | T-PUB-*] — [description]
- Agent: [agent name, session ID]
- Reason: [narrative explanation]
- Condition resolved: [yes/no/N/A]
- Status: [EXECUTED | REVERTED | PENDING]
```

---

### 2026-04-14 PUBLIC (initial state)

- Date/Time: 2026-04-14 (exact time unknown — before session records began)
- Direction: PRIVATE → PUBLIC
- Trigger: T-PUB-1 — GitHub Actions CI was broken due to billing/payment failure on private repo
- Agent: Owner (manual action via GitHub UI)
- Reason: All GitHub Actions workflows were failing with "The job was not started
  because recent account payments have failed or your spending limit needs to be
  increased." Making the repo public grants unlimited free Actions minutes and
  resolved all CI failures immediately.
- Condition resolved: Yes — CI now fully operational
- Status: EXECUTED ✅

---

*End of decision log. Append new entries above this line.*

---

## Governance Notes

- This file is tracked in git. Any modification must be committed.
- Agents operating under the CollabOps single-writer lock must include
  modifications to this file in their commit batch when they execute a toggle.
- If the CollabOps lock is held by another agent during an emergency toggle
  (T-PVT-1 or T-PVT-4), the toggling agent may act without the lock but must
  note this in the Decision Log entry and immediately notify the lock holder.
