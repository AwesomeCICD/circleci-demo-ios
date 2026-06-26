package org

# CircleCI config policy (OPA/Rego).
#
# This is the platform-team guardrail: it is enforced at the ORG level, so an
# individual developer cannot edit a repo's config to "ship faster" by removing
# the notarization gate. It complements the in-pipeline gate in
# .circleci/config.yml (verify_notarization.sh).
#
# Push it with:
#   circleci policy push ./policies --owner-id <your-org-id> --context config
# Validate locally with:
#   circleci policy test ./policies

import data.circleci.config
import future.keywords.in

policy_name["notarization_guardrails"]

# Every pipeline must include the release-gate job, which verifies Apple
# notarization before anything is published.
require_release_gate := config.require_jobs(["release-gate"])

enable_rule["require_release_gate"]
hard_fail["require_release_gate"]
