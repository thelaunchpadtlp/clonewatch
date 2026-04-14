# CloneWatch V1 Productized Gates

Date: 2026-04-14

This gate system is optimized for efficiency: do not start the next gate until current gate is green.

## Gate A - Operations (GitHub zero surprises)

Exit criteria:

- latest `main` relevant workflows are green or have documented infra blocker
- diagnostics script runs and explains failures with clear next action
- auth/access policy is documented and applied

## Gate B - Security and distribution hardening

Exit criteria:

- signing pipeline scaffolded
- notarization pipeline scaffolded
- hardened runtime checks documented and validated
- permission guidance docs complete

## Gate C - Product usability and accessibility

Exit criteria:

- run flow is didactic end-to-end for non-technical users
- accessibility baseline complete (labels/values/keyboard flow)
- error handling messages are clear and actionable

## Gate D - Release readiness

Exit criteria:

- release checklist complete
- rollback instructions validated
- final records synchronized (memory/roadmap/changelog)
- `main` health confirmed at release commit
