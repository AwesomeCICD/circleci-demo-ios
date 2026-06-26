#!/usr/bin/env bash
# Assemble the .app bundle that gets shipped inside the .dmg.
set -euo pipefail

VERSION="$(cat VERSION)"
APP="dist/Store Device Update Utility.app"

echo "==> Assembling ${APP} (v${VERSION})"
rm -rf "${APP}"
mkdir -p "${APP}/Contents/MacOS" "${APP}/Contents/Resources"
cp "dist/store-updater" "${APP}/Contents/MacOS/store-updater"
chmod +x "${APP}/Contents/MacOS/store-updater"

cat > "${APP}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>Store Device Update Utility</string>
    <key>CFBundleDisplayName</key>     <string>Store Device Update Utility</string>
    <key>CFBundleIdentifier</key>      <string>com.circleci.fieldeng.store-updater</string>
    <key>CFBundleExecutable</key>      <string>store-updater</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleShortVersionString</key> <string>${VERSION}</string>
    <key>CFBundleVersion</key>         <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>  <string>12.0</string>
    <key>NSHighResolutionCapable</key> <true/>
</dict>
</plist>
PLIST

echo "App bundle ready: ${APP}"
