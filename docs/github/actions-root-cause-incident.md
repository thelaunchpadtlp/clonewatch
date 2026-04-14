# Incident: GitHub Actions Failing Before Job Steps

Date opened: 2026-04-14  
Status: Open (infra/account-level blocker)

## Executive summary

CloneWatch workflows on `main` are failing immediately across multiple workflows (`CI`, `CodeQL`, `Memory Guard`, `Project Records Guard`, `Collab Guard`).

Observed signature:

- run conclusion: `failure`
- jobs complete in a few seconds
- `steps` array is empty (`steps: []`)
- pattern affects both macOS and Ubuntu workflows

This strongly indicates a GitHub Actions infrastructure/account policy issue, not a project code issue.

## Evidence

- latest failing runs (examples):
  - `24412683095` (`CI`)
  - `24412683102` (`CodeQL`)
  - `24412683115` (`Memory Guard`)
  - `24412683120` (`Project Records Guard`)
- job detail examples with empty steps:
  - `build-and-test` job id `71312863856`
  - `enforce-memory-update` job id `71312863791`

## What has already been done

- local code validated:
  - `swift build` passed
  - `swift test` passed
- reruns attempted on failing workflows
- repository Actions permissions checked (`enabled: true`, `allowed_actions: all`)
- diagnostics tooling added:
  - `tools/collab/diagnose-github-actions.sh`
  - `docs/github/actions-triage.md`
  - `docs/github/auth-access-policy.md`

## Most likely root-cause class

One or more of:

1. account-level Actions quota/spending/minutes exhausted
2. runner policy or entitlement restriction
3. org/account security/policy gating workflow execution before runner steps

## Required owner-side checks (GitHub web)

1. billing/actions usage and spending limit
2. runner availability policy for private repos
3. repository/org Actions policy constraints
4. auth mode that allows full diagnostics visibility from CLI/web

## External solver tasking notes

If an external tool/agent investigates this incident, it must:

1. read this file first
2. append findings to `docs/collab/external-outbox/`
3. include reproducible evidence (screenshots/URLs/error text)
4. avoid changing project code until infra blocker is cleared
