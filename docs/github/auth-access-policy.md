# GitHub Authentication and Access Policy (CloneWatch)

Date: 2026-04-14

## Goal

Keep operations observable and safe in a multi-agent/multi-app environment.

## Default principle

Do not use "more permissions by default".  
Use least-privilege profiles with explicit escalation when needed.

## Credential model

1. **Principal credential (daily operations)**
- used for normal pushes, PR ops, and workflow diagnostics
- must support workflow/check visibility
- rotate on schedule

2. **Break-glass credential (emergency only)**
- stored separately
- used only for blocked recovery/admin events
- rotate immediately after emergency use

## External access baseline

All **externos** must have at least:

- repo read
- metadata read
- Actions/workflow read

Write/admin are granted by role, not by default.

## Recommended token strategy by use case

- `gh` interactive diagnostics: prefer `gh auth login` OAuth
- automation app-to-app integrations: prefer fine-grained PAT with explicit repo scope
- emergency maintenance only: temporary elevated token, then revoke/rotate

## Rotation and audit

- token expiry required for non-emergency credentials
- track owner + tool + purpose + created/expires dates in project records
- remove unused credentials quickly

## Fast checklist for "cero sorpresas"

1. `gh auth status` works
2. `tools/collab/diagnose-github-actions.sh` runs cleanly
3. latest `main` workflow set is green or has root cause documented
4. no unknown high-privilege long-lived tokens
