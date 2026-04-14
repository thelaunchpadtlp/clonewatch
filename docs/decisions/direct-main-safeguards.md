# Decision: Direct Main Safeguards

Date: 2026-04-14

## Decision

Direct pushes to `main` are permitted only when all gates pass:

1. active writer lock is valid and owned by the session
2. repo is synchronized (`fetch` + divergence check)
3. validation checks pass (`swift build`, `swift test`, required guard scripts)
4. required records are updated (memory and project records rules)
5. handoff is written before lock release

## Fallback

If any gate fails, do not force direct main. Use branch fallback.

## Intent

Keep `main` usable and low-noise while still allowing efficient operation for solo operators.

