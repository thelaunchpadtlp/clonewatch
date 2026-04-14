# Incident: GitHub Actions Reliability and Merge-Gating Failures

Date opened: 2026-04-14  
Status: Resolved and documented

## Executive summary

Two separate but related GitHub Actions problems were observed and are now documented together:

1. **Repo-wide pre-step failures** on the private repository:
   - jobs completed in seconds
   - `steps` arrays were empty (`steps: []`)
   - pattern affected macOS and Ubuntu workflows
2. **Merge gating failure after CI recovery**:
   - PR #4 checks were green for `CI`, `CodeQL`, `Memory Guard`, and `Collab Guard`
   - merge was still blocked because branch rules required `Docs History Validation`
   - that workflow was path-filtered and therefore did not run on unrelated PRs

The first issue was infrastructure/account-level. The second issue was workflow/ruleset design.

## Incident A — repo-wide pre-step failures

- Representative failing runs:
  - `24412683095` (`CI`)
  - `24412683102` (`CodeQL`)
  - `24412683115` (`Memory Guard`)
  - `24412683120` (`Project Records Guard`)
- Representative job detail examples with empty steps:
  - `build-and-test` job id `71312863856`
  - `enforce-memory-update` job id `71312863791`

### What was done

- local code validated:
  - `swift build` passed
  - `swift test` passed
- reruns attempted on failing workflows
- repository Actions permissions checked (`enabled: true`, `allowed_actions: all`)
- diagnostics tooling added:
  - `tools/collab/diagnose-github-actions.sh`
  - `docs/github/actions-triage.md`
  - `docs/github/auth-access-policy.md`
- repository visibility changed to public, which removed the private-repo billing gate

### Root-cause conclusion

This first issue was consistent with GitHub account/repository execution gating rather than source-code failure. After the repository moved to public visibility, normal workflow execution resumed.

## Incident B — CodeQL SARIF conflict and merge gating

### Evidence

- CodeQL failed on PR #4 with:

  `Code Scanning could not process the submitted SARIF file: CodeQL analyses from advanced configurations cannot be processed when the default setup is enabled`

- Branch ruleset `Protect main` requires these checks:
  - `CI`
  - `CodeQL`
  - `Docs History Validation`
  - `Memory Guard`
- PR #4 was still blocked even after its main PR checks were green because `Docs History Validation` never ran on unrelated changes.

### What was done

1. Confirmed GitHub default Code Scanning setup was still active.
2. Disabled default setup via GitHub API so the repository's custom `codeql.yml` becomes the single source of truth.
3. Re-ran CodeQL and observed a successful run on PR #4.
4. Hardened the custom CodeQL workflow to:
   - use `github/codeql-action@v4`
   - run explicit `swift build` instead of relying on `autobuild`
5. Updated `Docs History Validation` so it always reports a result on PRs to `main`, while still skipping expensive regeneration when docs-history inputs did not change.

### Final root-cause refinement

After the workflow hardening landed, a final merge blocker still remained on PR #4 even though all visible PR checks were green.

The exact cause was a **ruleset-to-check-name mismatch**:

- the `Protect main` ruleset required these contexts:
  - `CI`
  - `CodeQL`
  - `Docs History Validation`
  - `Memory Guard`
- GitHub was actually emitting these actionable checks for the PR commit:
  - `build-and-test`
  - `CodeQL`
  - `validate-doc-history`
  - `enforce-memory-update`

This meant GitHub could only positively match 3 of the 4 required checks at merge time, even though the PR looked green in the UI.

### Final corrective action

The minimal and correct fix was to update the repository ruleset so that it requires the **actual emitted check names**:

- `build-and-test`
- `CodeQL`
- `validate-doc-history`
- `enforce-memory-update`

This ruleset correction was applied directly via GitHub API, after confirming there was no second hidden branch-protection layer.

### Result

- PR #4 merged successfully after the ruleset contexts were aligned with the emitted checks.
- CodeQL configuration is no longer split between GitHub default setup and custom workflow logic.
- `Docs History Validation` now always emits a required check on PRs to `main`.
- The repository now has a reproducible incident record covering:
  - private-repo execution gating
  - CodeQL/default-setup conflict
  - hidden merge blockage caused by ruleset/check-name mismatch

## External solver notes

If an external tool/agent investigates this incident, it must:

1. read this file first
2. append findings to `docs/collab/external-outbox/`
3. include reproducible evidence (screenshots/URLs/error text)
4. distinguish clearly between:
   - account/platform failures
   - workflow design failures
   - branch-ruleset merge failures
