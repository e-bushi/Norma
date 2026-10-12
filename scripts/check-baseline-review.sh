#!/bin/bash
# Fails when screenshot baselines change unless Designer Dan has signed off.
# Sign-off is the design-approved label plus a "Screenshot change:" sentence
# in the PR body explaining why the new pixels are intended.
#
# Local check:
#   PR_BODY="Screenshot change: ..." DESIGN_LABELS=design-approved \
#     bash scripts/check-baseline-review.sh <base-sha> <head-sha>

set -euo pipefail

cd "$(dirname "$0")/.."

base="${1:-}"
head="${2:-HEAD}"
if [[ -z "$base" ]]; then
  echo "usage: scripts/check-baseline-review.sh <base-sha> [head-sha]" >&2
  exit 1
fi

changed=$(git diff --name-only "$base" "$head" -- ScreenshotBaselines || true)
if [[ -z "$changed" ]]; then
  echo "No screenshot baseline changes."
  exit 0
fi

echo "Screenshot baselines changed:"
echo "$changed"

body="${PR_BODY:-}"
if [[ -z "$body" && -n "${GITHUB_EVENT_PATH:-}" ]]; then
  body=$(jq -r '.pull_request.body // ""' "$GITHUB_EVENT_PATH")
fi

labels="${DESIGN_LABELS:-}"
if [[ -z "$labels" && -n "${GITHUB_EVENT_PATH:-}" ]]; then
  labels=$(jq -r '.pull_request.labels // [] | .[].name' "$GITHUB_EVENT_PATH")
fi

failed=0
if ! printf '%s\n' "$body" | grep -q 'Screenshot change:'; then
  echo "::error::PR body must include a 'Screenshot change:' sentence explaining why the baseline change is intended."
  failed=1
fi

if ! printf '%s\n' "$labels" | grep -qx 'design-approved'; then
  echo "::error::Designer Dan must review these baselines. Add the design-approved label after Dan signs off."
  failed=1
fi

exit "$failed"
