#!/usr/bin/env bash
# Push the signed, notarized .dmg to external artifact storage. Uses S3 here;
# maps directly to Azure Blob in the team's environment. Non-fatal so a missing
# bucket/credential never breaks the demo (the .dmg is always available as a
# CircleCI build artifact regardless).
set -euo pipefail

VERSION="$(cat VERSION)"
DMG="$(ls dist/*.dmg 2>/dev/null | head -1)"

echo "==> Publishing ${DMG} to external artifact storage"
if [[ -n "${S3_BUCKET_NAME:-}" ]] && command -v aws >/dev/null 2>&1; then
    if aws s3 cp "${DMG}" "s3://${S3_BUCKET_NAME}/store-updates/$(basename "${DMG}")" \
        --metadata "version=${VERSION}"; then
        echo "Uploaded to s3://${S3_BUCKET_NAME}/store-updates/"
    else
        echo "NOTE: upload failed; artifact still available via CircleCI artifacts."
    fi
else
    echo "NOTE: S3_BUCKET_NAME unset or aws CLI unavailable — skipping external upload."
    echo "      (In your environment this step targets Azure Blob storage.)"
fi
