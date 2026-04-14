#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-thelaunchpadtlp/clonewatch}"
WORKFLOWS=("CI" "CodeQL" "Memory Guard" "Project Records Guard" "Collab Guard")

echo "== CloneWatch GitHub Actions diagnostics =="
echo "Repo: $REPO"
echo

if ! gh auth status >/dev/null 2>&1; then
  echo "ERROR: gh is not authenticated."
  exit 1
fi

echo "Auth check: ok"
echo

echo "Actions permissions:"
gh api "repos/$REPO/actions/permissions" || true
echo

echo "Latest run per relevant workflow:"
for wf in "${WORKFLOWS[@]}"; do
  run="$(gh run list --repo "$REPO" --workflow "$wf" --limit 1 --json databaseId,workflowName,displayTitle,status,conclusion,createdAt,url 2>/dev/null || true)"
  if [[ -z "$run" || "$run" == "[]" ]]; then
    echo "- $wf: no run found"
    continue
  fi

  id="$(printf '%s' "$run" | sed -n 's/.*"databaseId":[ ]*\([0-9][0-9]*\).*/\1/p' | head -n1)"
  status="$(printf '%s' "$run" | sed -n 's/.*"status":"\([^"]*\)".*/\1/p' | head -n1)"
  conclusion="$(printf '%s' "$run" | sed -n 's/.*"conclusion":"\([^"]*\)".*/\1/p' | head -n1)"
  url="$(printf '%s' "$run" | sed -n 's/.*"url":"\([^"]*\)".*/\1/p' | head -n1)"

  echo "- $wf: status=$status conclusion=$conclusion run_id=$id"

  if [[ "$conclusion" == "failure" && -n "$id" ]]; then
    details="$(gh run view "$id" --repo "$REPO" --json jobs 2>/dev/null || true)"
    if printf '%s' "$details" | grep -q '"steps":\[\]'; then
      echo "  hint: job failed before steps started (likely runner/policy/billing/account-level issue)."
    fi
    if printf '%s' "$details" | grep -q '"runner_id":0'; then
      echo "  hint: runner was not assigned."
    fi
    echo "  inspect: $url"
  fi
done

echo
echo "Check-run annotation permission probe:"
latest_fail_id="$(gh run list --repo "$REPO" --limit 20 --json databaseId,conclusion | sed -n 's/.*"databaseId":[ ]*\([0-9][0-9]*\).*"conclusion":"failure".*/\1/p' | head -n1)"
if [[ -n "$latest_fail_id" ]]; then
  check_url="$(gh run view "$latest_fail_id" --repo "$REPO" --json jobs 2>/dev/null | sed -n 's/.*"check_run_url":"\([^"]*\)".*/\1/p' | head -n1)"
  if [[ -n "$check_url" ]]; then
    if gh api "$check_url" >/dev/null 2>&1; then
      echo "check-run read: ok"
    else
      echo "check-run read: blocked (token lacks permission or token type limitation)."
      echo "recommendation: use gh OAuth login or classic PAT with proper scopes for diagnostics."
    fi
  fi
fi

echo
echo "Done."
