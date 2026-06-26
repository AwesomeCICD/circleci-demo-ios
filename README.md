# Store Device Update Utility — CircleCI demo (Starbucks)

A native **macOS** utility that builds the **USB recovery / update image** store
managers flash to in-store hardware (e.g. Mastrena ovens) when an over‑the‑air
update fails. The shippable artifact is a **signed, Apple‑notarized `.dmg`** —
not an `.ipa`, not a Docker image.

This branch exists to mirror what the IoT team actually does today and to show
how CircleCI removes the manual, error‑prone steps in between.

## The problem this models

- ARM (Apple Silicon) builds are done **by hand on engineers' laptops** because
  the current cloud CI (Azure) dropped Apple Silicon; Intel builds run on Azure.
- Releases are inconsistent. In one incident a build went out with **notarization
  turned off**, so in‑store devices rejected the `.dmg` as damaged and managers
  couldn't open it during a product launch.
- Rules that should be automatic (notarize, write the release back to the repo,
  store the artifact) live in people's heads.

## What the pipeline proves

| Their pain | Where it shows up in this pipeline |
| --- | --- |
| "Most of our fleet is Apple Silicon, some Intel — we want one place to build both" | `build-and-test` builds **one universal binary (arm64 + x86_64)** on a single managed **M4 Pro** executor |
| "Engineers build on their laptops; we don't want a Mac‑mini lab" | Builds run on **managed macOS** — nothing to maintain |
| "Someone disabled notarization and broke the stores" | `release-gate` **blocks publish** unless the `.dmg` is notarized (toggle it live with `skip-notarization`) |
| "CI should write the release back to GitHub" | `publish` **tags the repo** automatically |
| "We hand the build off / store it (Azure Blob)" | `publish` stores the `.dmg` as a build artifact and (optionally) uploads to S3 / Azure Blob |
| "Rules can't be optional" | `policies/notarization_required.rego` enforces the gate **org‑wide** |

## The pipeline (`.circleci/config.yml`)

1. **build-and-test** (macOS M4 Pro) — `swift test` (USB image hash‑verification
   tests) → universal `arm64 + x86_64` build → `.app` bundle → `.dmg` → code sign.
2. **release-gate** (macOS M4 Pro) — notarize the `.dmg`, then **verify** it.
   If notarization was skipped, this job fails and **publish never runs**.
3. **publish** — tag the release back to GitHub, store the `.dmg` artifact, and
   (when `publish-external=true`) push it to S3 / Azure Blob.

## Run the demo

Push to the `starbucks` branch (this branch). Then in the CircleCI UI:

- **Happy path** — pipeline is green; download the notarized `.dmg` from the
  `publish` job artifacts.
- **The money shot** — re‑run with the pipeline parameter **`skip-notarization = true`**
  (Trigger Pipeline → add parameter). `release-gate` turns red with a clear
  "RELEASE BLOCKED — devices would reject this" message, and `publish` is skipped.
- **External upload** (optional) — set **`publish-external = true`** in an org
  where S3/Azure creds are configured to see the artifact pushed to storage.

## How it maps to the Starbucks stack

- **Self‑hosted GitHub Enterprise Server** — connect via the CircleCI GHES
  integration (handled separately for `scm.starbucks.com`); the pipeline shape is
  identical.
- **Azure → CircleCI** — one managed Apple Silicon executor replaces both the
  Azure Intel agents and the manual laptop ARM builds (universal binary covers
  the whole fleet).
- **Azure Blob** — the `publish` upload step targets Azure Blob in your
  environment (S3 here for the FE demo org).
- **Governance** — config policies + SSO/SAML + contexts are the platform‑team
  "scale" layer for a POC.

## Local development

```bash
swift test                              # run the unit tests (needs full Xcode)
swift run store-updater version
swift run store-updater package --firmware fixtures/firmware --out /tmp/img
swift run store-updater verify  --image /tmp/img    # the in-store hash check
```

End‑to‑end packaging (build → app → dmg → sign → gate) is in `scripts/`; the CI
config calls these same scripts so what you run locally matches CI.

## Repo layout

```
Sources/StoreUpdaterCore/   # manifest + SHA-256 packaging/verification logic
Sources/store-updater/      # CLI (package / verify / version)
Tests/                      # USB image integrity tests (incl. tamper detection)
fixtures/firmware/          # sample oven firmware payload (demo stand-in)
scripts/                    # build_universal, make_app, make_dmg, sign, gate, publish
policies/                   # org-level config policy enforcing the notarization gate
.circleci/config.yml        # the pipeline
```
