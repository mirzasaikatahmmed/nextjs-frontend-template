#!/usr/bin/env bash
# Lock main: block direct pushes; merges only via pull request.
#
# Usage:
#   ./scripts/enable-branch-protection.sh
#   ./scripts/enable-branch-protection.sh owner/repo
#   BRANCH=main APPROVALS=1 ./scripts/enable-branch-protection.sh owner/repo
#
# Env:
#   BRANCH     target branch (default: main)
#   APPROVALS  required PR approvals (default: 1; use 0 for solo self-merge via PR)
#
# Requires: gh (logged in with admin access to the repo)

set -euo pipefail

BRANCH="${BRANCH:-main}"
APPROVALS="${APPROVALS:-1}"
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

RULESET_NAME="Lock ${BRANCH} - PR only"

echo "Locking '${BRANCH}' on ${REPO}"
echo "  - no direct pushes"
echo "  - PR required (${APPROVALS} approval(s))"
echo "  - status checks: scan-configs, build"
echo

ruleset_payload() {
  APPROVALS="$APPROVALS" BRANCH="$BRANCH" RULESET_NAME="$RULESET_NAME" python3 - <<'PY'
import json, os
approvals = int(os.environ["APPROVALS"])
branch = os.environ["BRANCH"]
name = os.environ["RULESET_NAME"]
print(json.dumps({
  "name": name,
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": [f"refs/heads/{branch}"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": approvals,
        "dismiss_stale_reviews": True,
        "require_code_owner_review": False,
        "require_last_push_approval": False,
        "required_review_thread_resolution": False
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": True,
        "do_not_enforce_on_create": False,
        "required_status_checks": [
          {"context": "scan-configs"},
          {"context": "build"}
        ]
      }
    },
    {"type": "non_fast_forward"},
    {"type": "deletion"}
  ],
  "bypass_actors": []
}))
PY
}

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

create_or_update_ruleset() {
  local payload existing_id
  payload="$(ruleset_payload)"
  existing_id="$(gh api "repos/${REPO}/rulesets" --jq ".[] | select(.name==\"${RULESET_NAME}\") | .id" 2>/dev/null || true)"

  if [[ -n "${existing_id}" ]]; then
    echo "Updating ruleset id=${existing_id}..."
    echo "$payload" | gh api "repos/${REPO}/rulesets/${existing_id}" -X PUT --input -
  else
    echo "Creating ruleset..."
    echo "$payload" | gh api "repos/${REPO}/rulesets" -X POST --input -
  fi
}

classic_protection() {
  echo "Falling back to classic branch protection API..."
  classic_payload | gh api "repos/${REPO}/branches/${BRANCH}/protection" \
    -X PUT \
    -H "Accept: application/vnd.github+json" \
    --input -
}

if create_or_update_ruleset; then
  echo
  echo "Ruleset active."
else
  echo
  classic_protection
  echo
  echo "Classic branch protection active (enforce_admins=true)."
fi

echo
echo "Verify in UI: https://github.com/${REPO}/settings/rules"
echo "Or: gh api repos/${REPO}/rulesets --jq '.[].name'"
echo
echo "Test: git push origin HEAD:${BRANCH}  → should be rejected"
echo "OK path: feature branch → PR → checks green → merge"
