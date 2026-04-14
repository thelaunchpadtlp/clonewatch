# Decision: macOS Prioritization Framework

Date: 2026-04-14

## Decision

Adopt a strict prioritization rule for feature intake:

1. First: improves clone/verify/evidence outcomes for non-technical users today
2. Second: strengthens reusable architecture and safety boundaries
3. Third: adds ecosystem integrations that provide measurable workflow value

If a candidate feature does not pass (1), it goes to `PENDING INTEGRAL`, not immediate implementation.

## Why

- keeps delivery fast and coherent
- reduces token/time waste from low-impact work
- prevents architecture drift from checklist overload

## Operational rule

Before implementation of a new capability, classify it as:

- NOW
- NEXT
- LATER
- PENDING INTEGRAL

and record the classification in roadmap + memory.
