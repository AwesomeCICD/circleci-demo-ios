# ios-game

[![CircleCI](https://circleci.com/gh/AwesomeCICD/circleci-demo-ios/tree/main.svg?style=svg)](https://circleci.com/gh/AwesomeCICD/circleci-demo-ios/tree/main)

This repository contains configuration files for a complete CI/CD pipeline for an iOS application using CircleCI, Fastlane Match, AWS S3, and AWS Amplify.

## Overview

The pipeline automates the following tasks:
- Building and testing the iOS application
- Managing signing certificates and provisioning profiles with fastlane match
- Uploading build artifacts to S3
- Publishing builds to TestFlight
- Integrating with AWS Amplify for mobile app backend services

## Prerequisites

- CircleCI account connected to your GitHub/Bitbucket repository
- Apple Developer account
- AWS account with S3 and Amplify configured
- Xcode project with proper signing and capabilities setup
- Private Git repository for storing certificates (fastlane match)

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
   
   For Field Engineering, the roles are:
      ```ruby
      circleci-demo-ios-role
      ```

### Certificate Management with Fastlane Match

This project uses **fastlane match** with a Git repository for secure, automated certificate and provisioning profile management. This approach provides:

- **Encrypted certificate storage** in a private Git repository
- **Automatic certificate renewal** when they expire
- **Team synchronization** - everyone gets the same certificates
- **Version control** for all signing assets
- **Zero-configuration** certificate management in CI/CD

#### Initial Setup

1. **Create a private Git repository** for storing certificates (e.g., `your-org/ios-certificates`)

2. **Update the Matchfile** with your repository URL:
   ```ruby
   git_url("https://github.com/your-org/ios-certificates")
   ```
   For Field Engineering this is:
      ```ruby
      git_url("https:/github.com/AwesomeCICD/circleci-match-credentials")
      ```
3. **Set up environment variables** (create a `.env` file locally):
   
   For Field Engineering, this exists in 1Password under `circleci-demo-ios`
   ```bash
   # Apple Developer Account
   APPLE_ID=your-apple-id@example.com
   TEAM_ID=YOUR_TEAM_ID

   # Match Configuration  
   MATCH_PASSWORD=your-strong-password
   MATCH_KEYCHAIN_PASSWORD=your-keychain-password

   # App Configuration
   APP_IDENTIFIER=com.circleci.ios-game-demo
   ```

4. **Generate certificates and provisioning profiles**:
   ```bash
   # Development certificates (for local development)
   fastlane match development

   # App Store certificates (for TestFlight/App Store)
   fastlane match appstore

   # Ad-hoc certificates (for internal distribution)
   fastlane match adhoc
   ```

### CircleCI Configuration

1. Add your project to CircleCI

2. Configure environment variables in CircleCI project settings:
   
   For Field Engineering these values will already exist. If you need to update them, they are located in 1Password under `circleci-demo-ios`
   - `APPLE_ID` - Your Apple Developer account email
   - `TEAM_ID` - Your Apple Developer Team ID
   - `MATCH_PASSWORD` - Password for encrypting certificates
   - `MATCH_KEYCHAIN_PASSWORD` - Keychain password (can be same as MATCH_PASSWORD)
   - `FASTLANE_USER` - Apple ID for App Store Connect
   - `FASTLANE_PASSWORD` - App-specific password for Apple ID
   - `APPLE_TEAM_ID` - Team ID for App Store Connect
   - `AWS_ACCESS_KEY_ID` (if not using IAM roles)
   - `AWS_SECRET_ACCESS_KEY` (if not using IAM roles)
   - `AWS_ROLE_ARN` (if using IAM role-based authentication)
   - `AWS_REGION` - AWS region for S3 and Amplify
   - `S3_BUCKET_NAME` - S3 bucket for build artifacts
   - `AMPLIFY_APP_ID` - Amplify application ID

3. Ensure the following files are in your repository:
   - `.circleci/config.yml`
   - `fastlane/Fastfile`
   - `fastlane/Appfile`
   - `fastlane/Matchfile`

## Usage

### Running the Pipeline

The CI/CD pipeline will automatically run when you push to your repository:
- Pushes to any branch will trigger the `build-and-test` job
- Pushes to `dev-*` branches will trigger both `build-and-test` and `adhoc` jobs
- Pushes to the `main` branch will trigger `build-and-test` and `beta` (TestFlight) jobs

### Manual Trigger

You can manually trigger a build in the CircleCI dashboard.

### Local Development

You can test the fastlane configuration locally:
```bash
# Run tests
fastlane test

# Build ad-hoc version
fastlane adhoc

# Build and upload to TestFlight
fastlane beta

# Sync certificates (readonly mode)
fastlane match development --readonly
fastlane match appstore --readonly
```

## Project Configuration

### App Details
- **Bundle Identifier**: `com.circleci.ios-game-demo`
- **Scheme**: `Game`
- **Target**: `Game`

### Customization

#### Project-Specific Changes

To adapt this project for your own app:

1. **Update bundle identifier** in:
   - `Game.xcodeproj/project.pbxproj`
   - `fastlane/Appfile`
   - `fastlane/Matchfile`

2. **Update scheme name** in:
   - `fastlane/Fastfile` (scan and gym actions)
   - `.circleci/config.yml`

3. **Create App ID** in Apple Developer Portal:
   ```bash
   fastlane produce -u your-apple-id@example.com -a your.bundle.identifier --skip_itc
   ```

#### Advanced Customization

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

## Architecture

### Certificate Management
- **Storage**: Private Git repository (encrypted)
- **Management**: Fastlane match
- **Types**: Development, Ad-hoc, App Store distribution
- **Renewal**: Automatic via fastlane match

### Build Artifacts
- **Storage**: AWS S3
- **Metadata**: Version and build information
- **Access**: Via AWS IAM roles in CircleCI

### Mobile Backend
- **Platform**: AWS Amplify
- **Integration**: Automatic deployment notifications
- **Services**: Authentication, API, Storage (configurable)

## Troubleshooting

### Common Issues

1. **Certificate Issues**
   - Ensure your match repository is correctly set up and accessible
   - Verify the `MATCH_PASSWORD` is correct
   - Check that your Apple ID has appropriate access to the team
   - Run `fastlane match development --readonly` to test certificate access

2. **Match Repository Access**
   - Ensure CircleCI has access to your certificates repository
   - Verify Git credentials or SSH keys are properly configured
   - Check that the repository URL in `Matchfile` is correct

3. **TestFlight Upload Failures**
   - Verify Apple ID has appropriate access in App Store Connect
   - Ensure app version and build numbers are incremented correctly
   - Check that the app meets Apple's guidelines
   - Verify `FASTLANE_PASSWORD` is an app-specific password

4. **AWS Integration Issues**
   - Verify IAM permissions for S3 and Amplify
   - Check S3 bucket policies and regional settings
   - Ensure Amplify app is correctly configured

5. **Bundle Identifier Issues**
   - Ensure the App ID exists in Apple Developer Portal
   - Verify the bundle identifier matches across all configuration files
   - Check that provisioning profiles are created for the correct App ID

## Maintenance

- **Certificates**: Automatically renewed by fastlane match (yearly)
- **Dependencies**: Regularly update fastlane and its plugins
- **AWS IAM**: Audit and update permissions as needed
- **Match Repository**: Backup and version control for certificates

## Security Notes

- Never commit `.env` files or plaintext certificates to version control
- Use app-specific passwords for Apple ID authentication
- Regularly rotate match passwords and update team access
- Use IAM roles instead of access keys when possible in CircleCI
- Keep the match repository private and limit access to necessary team members