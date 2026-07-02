# Org config policies

These are **CircleCI config policies** — org-level guardrails written in Rego
(OPA) that every pipeline is checked against *before it runs*.

`notarization_required.rego` requires the `release-gate` job (the job that
verifies Apple notarization) to be present in every workflow. A developer cannot
delete the gate from `.circleci/config.yml` to bypass notarization, because the
org policy would reject the config.

This is the layer that turns "we have a rule" into "the rule is enforced for
everyone." It pairs with SSO/SAML and contexts for the platform-team story in a
POC.

## Demo it live (no org changes needed)

```bash
# Run the policy's own tests
circleci policy test ./policies -v

# Today's config — gate present — PASSES
circleci policy decide ./policies --input .circleci/config.yml

# Same config with release-gate deleted — HARD_FAIL, pipeline would be
# blocked before a single job runs
circleci policy decide ./policies --input policies/demo/config-without-gate.yml
```

`policies/demo/config-without-gate.yml` is the real config with the
`release-gate` job removed — the exact edit a well-meaning developer might make
to "ship faster."

## Enforce for real

```bash
# Org admin, Scale plan. NOTE: push replaces the org's entire policy bundle —
# fetch the existing bundle first and add this policy alongside it.
circleci policy fetch --owner-id <ORG_ID>
circleci policy push <dir-with-full-bundle> --owner-id <ORG_ID> --context config
```
