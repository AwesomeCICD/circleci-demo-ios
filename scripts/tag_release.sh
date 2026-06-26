#!/usr/bin/env bash
# Write the release back to GitHub as a tag — the "CI updates the repo" step the
# team wants automated instead of done by hand. Non-fatal if the CI lacks write
# credentials, so the demo stays green.
set -euo pipefail

VERSION="$(cat VERSION)"
TAG="starbucks-demo/v${VERSION}-${CIRCLE_BUILD_NUM:-local}"

git config user.email "fieldeng@circleci.com"
git config user.name  "Field Engineering CI"

echo "==> Tagging release back to GitHub: ${TAG}"
if git rev-parse "${TAG}" >/dev/null 2>&1; then
    echo "NOTE: tag ${TAG} already exists; skipping."
    exit 0
fi

git tag -a "${TAG}" -m "Store device update ${VERSION} (notarized, published by CircleCI)"
if git push origin "${TAG}" 2>&1; then
    echo "Pushed tag ${TAG} to GitHub (write-back complete)."
else
    echo "NOTE: tag push failed (CI lacks write credentials in this run); tag created locally."
fi
