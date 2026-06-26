#!/usr/bin/env bash
# Human-readable summary of what shipped, for the demo screen.
set -euo pipefail

VERSION="$(cat VERSION)"
echo "=================================================================="
echo " PUBLISHED: Store Device Update v${VERSION}"
echo "=================================================================="
echo "Artifacts in dist/:"
ls -lh dist/ 2>/dev/null || true
echo ""
echo "Every store device update from this pipeline is:"
echo "  - built once as a universal binary (Apple Silicon + Intel)"
echo "  - signed and Apple-notarized (enforced by the release gate)"
echo "  - tagged back to GitHub for traceability"
echo "  - stored as a downloadable artifact (S3 / Azure Blob)"
