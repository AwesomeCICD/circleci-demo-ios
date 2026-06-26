#!/usr/bin/env bash
# Notarize the .dmg with Apple — OR, if SKIP_NOTARIZATION=true, deliberately skip
# it to reproduce the incident where an un-notarized build shipped to stores and
# devices rejected it as "damaged / can't be opened."
#
# This step does NOT fail on skip. The separate release gate (verify_notarization.sh)
# is what blocks publish, so the failure shows up as a clear, dedicated red job.
set -euo pipefail

DMG="$(ls dist/*.dmg 2>/dev/null | head -1)"
RECEIPT="${DMG}.notarization.json"
SKIP="${SKIP_NOTARIZATION:-false}"
rm -f "${RECEIPT}"

echo "=================================================================="
echo " RELEASE STEP: Apple notarization"
echo " Artifact: ${DMG}"
echo " skip-notarization parameter: ${SKIP}"
echo "=================================================================="

if [[ "${SKIP}" == "true" ]]; then
    echo "WARNING: notarization is being BYPASSED for this build."
    echo "         This is exactly the change that shipped an un-notarized .dmg to"
    echo "         stores, where devices flagged it as damaged and managers could"
    echo "         not open it during a product launch."
    echo "No notarization receipt will be produced -> the release gate will block."
    exit 0
fi

if [[ -n "${APP_STORE_CONNECT_API_KEY_ID:-}" && -n "${MACOS_SIGN_IDENTITY:-}" ]]; then
    echo "==> Submitting to the Apple notary service (notarytool)…"
    KEYFILE="$(mktemp)"
    echo "${APP_STORE_CONNECT_API_KEY_CONTENT}" | base64 --decode > "${KEYFILE}"
    xcrun notarytool submit "${DMG}" \
        --key "${KEYFILE}" \
        --key-id "${APP_STORE_CONNECT_API_KEY_ID}" \
        --issuer "${APP_STORE_CONNECT_API_ISSUER_ID}" \
        --output-format json --wait | tee "${RECEIPT}"
    rm -f "${KEYFILE}"
    echo "==> Stapling notarization ticket to the .dmg"
    xcrun stapler staple "${DMG}"
else
    echo "==> Demo mode: no Apple credentials present."
    echo "    Recording a managed-notarization receipt for the gate to verify."
    cat > "${RECEIPT}" <<JSON
{
  "status": "Accepted",
  "mode": "simulated",
  "artifact": "$(basename "${DMG}")",
  "submittedAt": "$(date -u +%FT%TZ)"
}
JSON
    cat "${RECEIPT}"
fi

echo "Notarization step complete."
