# GitHub Actions Triage Guide (CloneWatch)

## Official health rule

Repository health is decided by the latest commit on `main` for each relevant workflow:

- `CI`
- `CodeQL`
- `Memory Guard`
- `Project Records Guard`
- `Collab Guard`

Older red runs do not block current decisions unless the same workflow is red on latest `main`.

## Noise handling

- Dependabot bot runs are intentionally reduced/filtered.
- Historical failures are retained by GitHub but should not drive current release decisions.

## If latest `main` has red checks

1. open failing workflow log
2. identify root error
3. patch with smallest safe change
4. rerun checks
5. update memory/changelog/roadmap if behavior or process changed

If jobs fail in seconds and show empty step lists (`steps: []`), treat as infra-class failure first:

1. run `tools/collab/diagnose-github-actions.sh`
2. verify Actions permissions (`gh api repos/<owner>/<repo>/actions/permissions`)
3. verify account/org constraints:
   - Actions minutes/quota/spending limit
   - runner policy availability
   - repository/org policy restrictions
4. only after infra is healthy, debug project code.

## If a stale bot branch keeps noise alive

- close/recreate the bot branch or PR cleanly
- keep an explicit note in project memory for auditability

## PR and check terminology (for beginners)

- **PR (Pull Request)**: proposed change set for review before merge.
- **No PRs open**: there are currently no active change proposals in review.
