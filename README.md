# ios-game

[![CircleCI](https://circleci.com/gh/AwesomeCICD/circleci-demo-ios/tree/main.svg?style=svg)](https://circleci.com/gh/AwesomeCICD/circleci-demo-ios/tree/main)

This repository contains configuration files for a complete CI/CD pipeline for an iOS application using CircleCI, Fastlane, AWS S3, and AWS Amplify.


## Overview

The pipeline automates the following tasks:
- Building and testing the iOS application
- Managing signing certificates and provisioning profiles
- Uploading build artifacts to S3
- Publishing builds to TestFlight
- Integrating with AWS Amplify for mobile app backend services

## Prerequisites

- CircleCI account connected to your GitHub/Bitbucket repository
- Apple Developer account
- AWS account with S3 and Amplify configured
- Xcode project with proper signing and capabilities setup

## Setup Instructions

### AWS Configuration


1. Create an S3 bucket for storing artifacts:
   ```bash
   aws s3 mb s3://your-app-artifacts-bucket
   ```

2. Set up AWS Amplify for your project:
   ```bash
   npm install -g @aws-amplify/cli
   amplify init
   amplify add auth
   amplify add api
   amplify push
   ```

3. Create an IAM user with appropriate permissions for S3 and Amplify, and note the access key and secret key.

### Certificate Management

This project uses S3 for certificate storage rather than fastlane match's git-based approach. This simplifies CI/CD but requires a ONE TIME initial setup. If you need to generate new certs for a yearly refresh or security concern, instructions are below.

1. Export your certificates and provisioning profiles:
   - Open Keychain Access and export your development and distribution certificates
   - Download provisioning profiles from Apple Developer Portal
   - Or use Xcode to manage your certificates and profiles initially

2. Package and upload certificates to S3:
   ```bash
   cp .env.example .env
   # Edit .env with your credentials
   source .env
   chmod +x scripts/setup_certificates.sh
   ./scripts/setup_certificates.sh
   ```

3. Verify the certificates were uploaded successfully:
   ```bash
   aws s3 ls s3://${S3_BUCKET_NAME}/certificates/
   ```

Note: This approach differs from the standard fastlane match workflow. We're directly managing certificates in S3 rather than using a git repository.

### CircleCI Configuration

1. Add your project to CircleCI

2. Configure environment variables in CircleCI project settings:
   - `APPLE_ID`
   - `TEAM_ID`
   - `MATCH_PASSWORD`
   - `MATCH_KEYCHAIN_PASSWORD`
   - `AWS_ACCESS_KEY_ID` (if not using IAM roles)
   - `AWS_SECRET_ACCESS_KEY` (if not using IAM roles)
   - `AWS_ROLE_ARN` (if using IAM role-based authentication)
   - `AWS_REGION`
   - `S3_BUCKET_NAME`
   - `AMPLIFY_APP_ID`

3. Ensure the following files are in your repository:
   - `.circleci/config.yml`
   - `fastlane/Fastfile`
   - `fastlane/Appfile`

## Usage

### Running the Pipeline

The CI/CD pipeline will automatically run when you push to your repository:
- Pushes to any branch will trigger the `build-and-test` job
- Pushes to the `main` branch will trigger both `build-and-test` and `deploy-testflight` jobs

### Manual Trigger

You can manually trigger a build in the CircleCI dashboard.

### Local Testing

You can test the fastlane configuration locally:
```bash
fastlane test
fastlane beta
```

## Customization

### Project-Specific Changes

Replace the following placeholders in the configuration files:
- `YourAppScheme` with your Xcode scheme name
- `com.example.yourapp` with your app's bundle identifier

### Advanced Customization

- Modify the `Fastfile` to add additional lanes for different deployment targets
- Add post-processing steps in CircleCI config for notifications or additional integrations
- Enhance the AWS integration with additional services like CloudWatch for monitoring
- The config uses the CircleCI AWS CLI orb for improved security and simplicity

### AWS Orbs

This project uses the following CircleCI orbs for AWS interactions:

#### AWS CLI Orb
The [CircleCI AWS CLI orb](https://circleci.com/developer/orbs/orb/circleci/aws-cli) provides:
- Simplified AWS authentication
- Support for IAM roles and temporary credentials
- Automatic AWS CLI installation
- Standardized AWS CLI configuration

#### AWS S3 Orb
The [CircleCI AWS S3 orb](https://circleci.com/developer/orbs/orb/circleci/aws-s3) provides:
- Specialized commands for S3 operations (like `aws-s3/copy`)
- File syncing capabilities
- Transfer optimization
- Built-in metadata tagging for build identification
- Improved error handling for S3 operations
- Consistent patterns for file uploads and downloads

Example in our config:
```yaml
- aws-s3/copy:
    from: ${ZIP_NAME}
    to: s3://${S3_BUCKET_NAME}/builds/
    arguments: |
      --metadata "appVersion=${APP_VERSION},buildNumber=${BUILD_NUMBER}"
```

## Troubleshooting

### Common Issues

1. **Certificate Issues**
   - Ensure your match repository is correctly set up
   - Verify the keychain password is correct
   - Check that provisioning profiles match your app's bundle identifier

2. **TestFlight Upload Failures**
   - Verify Apple ID has appropriate access in App Store Connect
   - Ensure app version and build numbers are incremented correctly
   - Check that the app meets Apple's guidelines

3. **AWS Integration Issues**
   - Verify IAM permissions
   - Check S3 bucket policies
   - Ensure Amplify app is correctly configured

## Maintenance

- Regularly update fastlane and its plugins
- Rotate certificates as needed (typically yearly)
- Audit and update AWS IAM permissions