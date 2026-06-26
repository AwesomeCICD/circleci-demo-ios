#!/usr/bin/env bash
# Package the .app into the .dmg that a store manager mounts / flashes to USB.
# This .dmg is the real shippable artifact (not an .ipa, not a Docker image).
set -euo pipefail

VERSION="$(cat VERSION)"
APP="dist/Store Device Update Utility.app"
DMG="dist/StoreDeviceUpdateUtility-${VERSION}.dmg"

echo "==> Building ${DMG}"
rm -f "${DMG}"
STAGE="$(mktemp -d)"
cp -R "${APP}" "${STAGE}/"
hdiutil create -volname "Store Update ${VERSION}" \
    -srcfolder "${STAGE}" -ov -format UDZO "${DMG}" >/dev/null
rm -rf "${STAGE}"

echo "DMG ready: ${DMG}"
ls -lh "${DMG}"
