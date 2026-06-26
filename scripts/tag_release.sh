#!/usr/bin/env bash
# Write the release back to GitHub as a tag — the "CI updates the repo" step the
# team wants automated instead of done by hand.
#
# Write-back uses a write-scoped token (GH_PAT) over HTTPS, which is the
# credential the platform team controls for CI. Without it, the tag is created in
# the workspace and the step stays clean (the project's read-only checkout key
# cannot push).
set -euo pipefail

VERSION="$(cat VERSION)"
TAG="starbucks-demo/v${VERSION}-${CIRCLE_BUILD_NUM:-local}"

git config user.email "fieldeng@circleci.com"
git config user.name  "Field Engineering CI"

echo "==> Preparing release tag: ${TAG}"
git tag -fa "${TAG}" -m "Store device update ${VERSION} (notarized, published by CircleCI)" >/dev/null 2>&1 || true

if [[ -n "${GH_PAT:-}" ]]; then
    REPO_PATH="$(git remote get-url origin | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')"
    if git push "https://x-access-token:${GH_PAT}@github.com/${REPO_PATH}.git" "${TAG}" >/dev/null 2>&1; then
        echo "Write-back complete: pushed tag ${TAG} to GitHub."
    else
        echo "NOTE: tag push was rejected by GitHub; tag created in the workspace only."
    fi
else
    echo "Tag ${TAG} created. Set a write-scoped GH_PAT project env var to push it back to GitHub."
fi
