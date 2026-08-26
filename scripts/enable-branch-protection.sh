#!/usr/bin/env bash
# Lock main: block direct pushes; merges only via pull request.
#
# Usage:
#   ./scripts/enable-branch-protection.sh
#   ./scripts/enable-branch-protection.sh owner/repo
#   APPROVALS=0 ./scripts/enable-branch-protection.sh owner/repo
#
# Env:
#   BRANCH     target branch (default: main)
#   APPROVALS  required PR approvals (default: 0 for solo; use 1+ for teams)
#
# Requires: gh (logged in with admin access to the repo)

set -euo pipefail

BRANCH="${BRANCH:-main}"
APPROVALS="${APPROVALS:-0}"
REPO="${1:-}"

if [[ -z "$REPO" ]]; then
  url="$(git remote get-url origin 2>/dev/null || true)"
  if [[ -z "$url" ]]; then
    echo "ERROR: pass owner/repo or set git remote origin" >&2
    exit 1
  fi
  REPO="$(echo "$url" | sed -E 's#(git@github\.com:|https://github\.com/)##; s#\.git$##')"
fi

if ! command -v gh >/dev/null; then
  echo "ERROR: GitHub CLI (gh) is required — https://cli.github.com" >&2
  exit 1
fi

if ! command -v python3 >/dev/null; then
  echo "ERROR: python3 is required to build the API payload" >&2
  exit 1
fi

echo "Locking '${BRANCH}' on ${REPO}"
echo "  - no direct pushes to ${BRANCH}"
echo "  - PR required (${APPROVALS} approval(s))"
echo "  - status checks: scan-configs, build"
echo

# Show current protection if any
if gh api "repos/${REPO}/branches/${BRANCH}/protection" --jq '.required_pull_request_reviews.required_approving_review_count' 2>/dev/null; then
  echo "Updating existing branch protection..."
else
  echo "Enabling branch protection (classic API)..."
fi

classic_payload() {
  APPROVALS="$APPROVALS" python3 - <<'PY'
import json, os
approvals = int(os.environ["APPROVALS"])
print(json.dumps({
  "required_status_checks": {
    "strict": True,
    "contexts": ["scan-configs", "build"]
  },
  "enforce_admins": True,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": True,
    "require_code_owner_reviews": False,
    "required_approving_review_count": approvals
  },
  "restrictions": None,
  "required_linear_history": True,
  "allow_force_pushes": False,
  "allow_deletions": False,
  "block_creations": False,
  "required_conversation_resolution": False
}))
PY
}

classic_payload | gh api "repos/${REPO}/branches/${BRANCH}/protection" \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  --input -

echo
echo "Branch protection active on ${BRANCH} (enforce_admins=true)."
echo
echo "Verify: https://github.com/${REPO}/settings/branches"
gh api "repos/${REPO}/branches/${BRANCH}/protection" --jq '{
  pr_approvals: .required_pull_request_reviews.required_approving_review_count,
  enforce_admins: .enforce_admins.enabled,
  checks: .required_status_checks.contexts,
  force_push: .allow_force_pushes.enabled
}' 2>/dev/null || true
echo
echo "Test: git push origin HEAD:${BRANCH}  → should be rejected"
echo "OK path: feature branch → PR → checks green → merge"
