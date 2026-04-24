# circleci-demo-ios — BCP Demo Branch

[![CircleCI](https://circleci.com/gh/AwesomeCICD/circleci-demo-ios/tree/bcp-demo.svg?style=svg)](https://circleci.com/gh/AwesomeCICD/circleci-demo-ios/tree/bcp-demo)

A CircleCI pipeline demo modelling a two-stage brownfield mobile architecture — React Native mini-apps bundling on Linux, handing off to a native iOS shell building on macOS, through security scanning to TestFlight and App Store submission.

---

## Pipeline Architecture

```
[Build RN: Payments] ─┐
                       ├─ [upload-artifacts] ─ [validate] ─ [build-native-shell] ─ [security-scans] ─ [deploy-testflight] ─ [approve-release] ─ [submit-app-store]
[Build RN: Transfers] ─┘
```

---

## Jobs

### Stage 1 — React Native Mini-Apps (Linux, parallel)

**`build-rn-miniapp`**
Parameterized job. Takes `miniapp_name` and `miniapp_path` as parameters. Runs `npm install`, bundles the RN app for iOS using Metro bundler, packages the output to a `.tar.gz` artifact, and persists it to the workspace.

**`upload-artifacts`**
Attaches workspace, authenticates to AWS via OIDC, and uploads all mini-app artifacts to S3 under `builds/miniapp-artifacts/<build-num>/`.

---

### Stage 2 — Native iOS Shell (macOS)

**`validate`**
Attaches workspace, verifies mini-app artifacts from Stage 1, runs Fastlane validation lane.

**`build-native-shell`**
Attaches workspace, extracts RN bundles, runs Fastlane test lane to build the native iOS shell app.

**`security-scans`**
Real Snyk dependency scan against `miniapps/payments` via the `snyk/snyk` orb. SonarQube analysis (simulated).

**`deploy-testflight`**
Runs `fastlane beta` to deploy to TestFlight. Generates a QR code via the `tadashi0713/app-distribution` orb and posts it to Slack. Uploads build info JSON to S3 and updates Amplify.

**`approve-release`**
Manual approval gate. Pipeline pauses here until a human approves in the CircleCI UI.

**`submit-app-store`**
Runs after approval. Simulates App Store submission via `fastlane deliver` and sends a Slack notification.

---

## Mini-App Projects

Two minimal React Native projects under `miniapps/`:

```
miniapps/
├── payments/
│   ├── package.json
│   ├── index.js
│   ├── babel.config.js
│   ├── metro.config.js
│   └── src/App.js
└── transfers/
    ├── package.json
    ├── index.js
    ├── babel.config.js
    ├── metro.config.js
    └── src/App.js
```

The `react-native bundle` command runs for real and produces a valid iOS `.jsbundle`.

---

## Orbs

| Orb | Version | Purpose |
|---|---|---|
| `circleci/aws-cli` | 5.4.0 | OIDC-based AWS authentication |
| `circleci/aws-s3` | 4.1.1 | S3 artifact upload/copy |
| `circleci/slack` | 4.14.0 | Slack notifications |
| `snyk/snyk` | 2.3.0 | Dependency vulnerability scanning |
| `tadashi0713/app-distribution` | 1.2.0 | QR code generation and Slack distribution |

---

## Environment Variables

| Variable | Purpose |
|---|---|
| `AWS_ROLE_ARN` | IAM role ARN for OIDC assumption |
| `AWS_REGION` | AWS region |
| `S3_BUCKET_NAME` | Artifact storage bucket |
| `SNYK_TOKEN` | Snyk API token |
| `CIRCLE_TOKEN` | CircleCI API token (for QR code generation) |
| `SLACK_ACCESS_TOKEN` | Slack bot token |
| `SLACK_DEFAULT_CHANNEL` | Default Slack channel |

Apple and Fastlane credentials are stored in 1Password under `circleci-demo-ios`.
