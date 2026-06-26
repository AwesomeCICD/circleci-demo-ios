#!/usr/bin/env bash
# Code sign the app. With a real Developer ID (MACOS_SIGN_IDENTITY) we use it;
# otherwise we apply an ad-hoc signature so the demo runs anywhere.
set -euo pipefail

APP="dist/Store Device Update Utility.app"
DMG="$(ls dist/*.dmg 2>/dev/null | head -1 || true)"

if [[ -n "${MACOS_SIGN_IDENTITY:-}" ]]; then
    echo "==> Code signing with Developer ID: ${MACOS_SIGN_IDENTITY}"
    codesign --force --deep --options runtime --timestamp \
        --sign "${MACOS_SIGN_IDENTITY}" "${APP}"
    [[ -n "${DMG}" ]] && codesign --force --timestamp --sign "${MACOS_SIGN_IDENTITY}" "${DMG}"
else
    echo "==> No Developer ID configured — applying ad-hoc signature (demo mode)"
    codesign --force --deep --sign - "${APP}"
fi

echo "==> Verifying signature on the app bundle"
codesign --verify --deep --verbose=2 "${APP}" || true
