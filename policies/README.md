# Org config policies

These are **CircleCI config policies** — org-level guardrails written in Rego
(OPA) that every pipeline is checked against *before it runs*.

`notarization_required.rego` requires the `release-gate` job (the job that
verifies Apple notarization) to be present in the pipeline. A developer cannot
delete the gate from `.circleci/config.yml` to bypass notarization, because the
org policy would reject the config.

This is the layer that turns "we have a rule" into "the rule is enforced for
everyone." It pairs with SSO/SAML and contexts for the platform-team story in a
POC.

```bash
# Validate the policy bundle
circleci policy test ./policies

# Enforce it for the org
circleci policy push ./policies --owner-id <ORG_ID> --context config
```

> Note: helper names (e.g. `config.require_jobs`) follow the CircleCI config-policy
> SDK; run `circleci policy test` to validate before pushing.
