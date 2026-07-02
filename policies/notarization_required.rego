package org

# CircleCI config policy (OPA/Rego).
#
# This is the platform-team guardrail: it is enforced at the ORG level, so an
# individual developer cannot edit a repo's config to "ship faster" by removing
# the notarization gate. It complements the in-pipeline gate in
# .circleci/config.yml (verify_notarization.sh).
#
# Validate locally with:
#   circleci policy test ./policies
# See a live decision against a config with:
#   circleci policy decide ./policies --input .circleci/config.yml
# Enforce for the org (org admin, Scale plan) with:
#   circleci policy push ./policies --owner-id <your-org-id> --context config

import data.circleci.utils
import future.keywords.in

policy_name["notarization_guardrails"]

# Every workflow must include the release-gate job, which verifies Apple
# notarization before anything is published.
require_release_gate[workflow_name] = reason {
	some workflow_name, workflow in input.workflows
	is_object(workflow)
	not workflow_has_release_gate(workflow)
	reason := sprintf("workflow '%s' must include the 'release-gate' job — releases cannot ship without verified Apple notarization", [workflow_name])
}

workflow_has_release_gate(workflow) {
	some job in workflow.jobs
	utils.get_element_name(job) == "release-gate"
}

enable_rule["require_release_gate"]

hard_fail["require_release_gate"]

# OPA tests — run with: circleci policy test ./policies
test_gate_present {
	count(require_release_gate) == 0 with input as {"workflows": {"store-device-update": {"jobs": ["build-and-test", {"release-gate": {"requires": ["build-and-test"]}}]}}}
}

test_gate_missing_is_violation {
	count(require_release_gate) == 1 with input as {"workflows": {"store-device-update": {"jobs": ["build-and-test", "publish"]}}}
}
