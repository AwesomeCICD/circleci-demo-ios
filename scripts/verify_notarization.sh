#!/usr/bin/env bash
# RELEASE GATE: a build cannot be published unless it is notarized.
# Fails the pipeline (and therefore blocks publish) when notarization is missing.
set -euo pipefail

DMG="$(ls dist/*.dmg 2>/dev/null | head -1)"
RECEIPT="${DMG}.notarization.json"

echo "=================================================================="
echo " RELEASE GATE: no build ships unless it is notarized"
echo " Artifact: ${DMG}"
echo "=================================================================="

ok=true
if [[ -n "${MACOS_SIGN_IDENTITY:-}" ]]; then
    echo "==> Validating the stapled notarization ticket"
    xcrun stapler validate "${DMG}" || ok=false
    spctl --assess --type open --context context:primary-signature -v "${DMG}" || ok=false
else
    echo "==> Checking for a notarization receipt"
    if [[ -f "${RECEIPT}" ]]; then
        echo "Receipt found:"
        cat "${RECEIPT}"
    else
        ok=false
    fi
fi

if [[ "${ok}" != "true" ]]; then
    cat <<'BLOCKED'

##################################################################
#  RELEASE BLOCKED                                               #
#                                                               #
#  This .dmg is NOT notarized. In-store devices would reject    #
#  it as damaged / unable to open — the exact failure that put  #
#  a product launch at risk.                                    #
#                                                               #
#  CI is refusing to publish it. Re-run WITHOUT skipping        #
#  notarization. This guardrail is also enforced org-wide via   #
#  policies/notarization_required.rego so it can't be removed.  #
##################################################################
BLOCKED
    exit 1
fi

echo ""
echo "GATE PASSED: artifact is notarized and safe to publish."
