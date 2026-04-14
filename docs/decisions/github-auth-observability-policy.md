# Decision: GitHub Auth and Observability Policy

Date: 2026-04-14

## Decision

Use a two-tier credential model:

1. principal operational credential (daily work)
2. break-glass emergency credential (temporary, rotated after use)

Reject "maximum permissions by default" as standard practice.

## Why

- improve workflow diagnostics reliability
- reduce security risk from over-privileged long-lived credentials
- support multi-agent operation with clear accountability

## Operational rule

"GitHub zero surprises" requires:

- latest `main` checks interpreted as source of truth
- reproducible diagnostics (`tools/collab/diagnose-github-actions.sh`)
- explicit documentation of infra-level blockers (minutes/policy/runners)
