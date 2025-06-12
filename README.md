# ios-game

[![CircleCI](https://circleci.com/gh/AwesomeCICD/circleci-demo-ios/tree/main.svg?style=svg)](https://circleci.com/gh/AwesomeCICD/circleci-demo-ios/tree/main)

This repository contains configuration files for a complete CI/CD pipeline for an iOS application using CircleCI, Fastlane Match, AWS S3, and AWS Amplify.

## About the iOS Application

This is a simple **iOS game application** built with Swift and SpriteKit that demonstrates modern iOS development and CI/CD practices. The app serves as a practical example for setting up automated iOS build pipelines.

### What the App Does
- **Simple Touch Game**: Tap the screen to spawn rotating spaceships
- **SpriteKit Graphics**: Uses Apple's 2D game framework
- **iOS Native**: Built entirely in Swift using Xcode
- **Universal**: Runs on iPhone and iPad devices

### App Features
- Touch-based interaction
- Animated sprite graphics
- Portrait and landscape orientation support
- iOS 9.0+ compatibility
- Accessibility support

## iOS Development Prerequisites

If you're new to iOS development, you'll need:

### Required Software
- **macOS**: iOS development requires a Mac computer
- **Xcode**: Apple's official IDE (free from Mac App Store)
- **iOS Simulator**: Included with Xcode for testing
- **Apple Developer Account**: Free for local development, paid ($99/year) for App Store distribution

### Recommended Knowledge
- **Swift Programming Language**: Apple's modern programming language
- **iOS SDK**: Understanding of UIKit and iOS frameworks
- **Xcode IDE**: Basic navigation and project management
- **Git**: Version control (for collaboration)

### Setting Up Your Development Environment

1. **Install Xcode**:
   ```bash
   # Install from Mac App Store or Apple Developer Portal
   # Current version: Xcode 16.2.0 (as specified in CI config)
   ```

2. **Install Xcode Command Line Tools**:
   ```bash
   xcode-select --install
   ```

3. **Verify Installation**:
   ```bash
   xcode-select -p
   # Should output: /Applications/Xcode.app/Contents/Developer
   ```

## Project Structure

Understanding the iOS project layout:

```
Game.xcodeproj/          # Xcode project file (main project configuration)
├── project.pbxproj      # Project settings and file references

Game/                    # Main application source code
├── AppDelegate.swift    # App lifecycle management
├── GameScene.swift      # Main game logic and sprite handling
├── GameViewController.swift # View controller for the game scene
├── GameScene.sks        # SpriteKit scene file
├── Main.storyboard      # Interface layout
├── LaunchScreen.storyboard # App launch screen
├── Assets.xcassets      # App icons and images
└── Info.plist          # App configuration and metadata

GameTests/               # Unit tests
├── GameTests.swift      # Test cases for app logic
└── Info.plist          # Test bundle configuration

GameUITests/             # UI/Integration tests
├── GameUITests.swift    # UI test automation
├── SnapshotHelper.swift # Fastlane snapshot helper
└── Info.plist          # UI test bundle configuration

fastlane/               # Build automation
├── Fastfile            # Build lanes and automation scripts
├── Appfile             # App configuration
├── Matchfile           # Certificate management
├── Snapfile            # Screenshot automation
└── Gymfile             # Build settings
```

## Local Development Guide

### Opening the Project

1. **Navigate to Project Directory**:
   ```bash
   cd /path/to/circleci-demo-ios
   ```

2. **Open in Xcode**:
   ```bash
   open Game.xcodeproj
   ```
   Or double-click `Game.xcodeproj` in Finder

### Building and Running

#### Using Xcode (Recommended for Development)

1. **Select Target Device**:
   - Choose "iPhone 16 Pro" simulator from the device menu
   - Or connect a physical iOS device

2. **Build and Run**:
   - Press `Cmd + R` or click the "Play" button
   - Xcode will compile and launch the app

3. **Interacting with the App**:
   - Tap anywhere on the screen to spawn spaceships
   - Watch them rotate and accumulate on screen

#### Using Command Line

1. **List Available Simulators**:
   ```bash
   xcrun simctl list devices available | grep iPhone
   ```

2. **Build for Simulator**:
   ```bash
   xcodebuild -scheme Game -project Game.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
   ```

3. **Run Tests**:
   ```bash
   xcodebuild -scheme Game -project Game.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
   ```

### Using Fastlane for Local Development

Fastlane provides automated build scripts:

1. **Install Dependencies**:
   ```bash
   bundle install
   ```

2. **Run Tests**:
   ```bash
   bundle exec fastlane test
   ```

3. **Build Ad-hoc Version**:
   ```bash
   bundle exec fastlane adhoc
   ```

4. **Take Screenshots**:
   ```bash
   bundle exec fastlane snapshot
   ```

## Understanding the Game Code

### Core Game Logic (`GameScene.swift`)

#### What This Code Does

The `GameScene.swift` file creates an interactive game where:
1. **App starts** → Shows "Hello, World!" text in center of screen
2. **User taps anywhere** → A spaceship appears at that exact location
3. **Spaceship spins** → Each spaceship rotates continuously forever
4. **Multiple taps** → More spaceships accumulate on screen

#### Breaking Down the Code

```swift
class GameScene: SKScene {
    // This class inherits from SKScene, which is Apple's base class for 2D games
    
    override func didMove(to view: SKView) {
        // This function runs ONCE when the game scene first loads
        // Think of it like "setup" or "initialization"
        
        let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Hello, World!"
        myLabel.position = CGPoint(x:self.frame.midX, y:self.frame.midY)
        self.addChild(myLabel)
        // Creates a text label, positions it in the center, adds it to the scene
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // This function runs EVERY TIME the user touches the screen
        // It's an "event handler" - responds to user interaction
        
        for touch in touches {
            // Loop through all finger touches (supports multi-touch)
            
            let location = touch.location(in: self)
            // Get the exact X,Y coordinates where the user tapped
            
            let sprite = SKSpriteNode(imageNamed:"Spaceship")
            sprite.position = location
            // Create a spaceship image and place it at the tap location
            
            let action = SKAction.rotate(byAngle: CGFloat(Double.pi), duration:1)
            sprite.run(SKAction.repeatForever(action))
            // Make the spaceship spin: rotate 180° every 1 second, forever
            
            self.addChild(sprite)
            // Add the spaceship to the game scene (makes it visible)
        }
    }
}
```

#### Why This Matters

**1. Event-Driven Programming**
- iOS apps respond to user actions (touches, swipes, taps)
- `touchesBegan` is called automatically by iOS when user touches screen
- You don't call this function yourself - iOS calls it for you

**2. Object-Oriented Design**
- Everything is an object: labels, sprites, actions
- Objects have properties (`position`, `text`) and behaviors (`run`, `addChild`)
- This is fundamental to iOS development

**3. Coordinate System Understanding**
- iOS uses a coordinate system: (0,0) is bottom-left corner
- `self.frame.midX, self.frame.midY` = center of screen
- Critical for positioning UI elements and game objects

**4. Memory Management**
- Each `addChild()` adds an object to memory
- Too many objects can slow down the app
- Production apps need cleanup logic (not shown in this simple demo)

**5. Animation and Actions**
- `SKAction` is Apple's animation system
- Animations can be chained, repeated, and combined
- Essential for creating engaging user interfaces

#### Real-World Applications

This simple pattern scales to complex iOS apps:
- **Social Apps**: User taps "Like" → Heart animation appears
- **Shopping Apps**: User taps product → Detail view slides in
- **Games**: User swipes → Character moves, enemies spawn
- **Productivity Apps**: User taps button → Form validates, data saves


## Testing and Debugging

### Running Unit Tests

```bash
# Using Xcode: Cmd + U
# Using command line:
xcodebuild -scheme Game -project Game.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

### UI Testing

The project includes UI tests for automated testing:

```swift
// Example UI test
func testLaunchPerformance() {
    measure(metrics: [XCTApplicationLaunchMetric()]) {
        XCUIApplication().launch()
    }
}
```

### Debugging Tips

1. **Use Breakpoints**: Click line numbers in Xcode to set breakpoints
2. **Console Output**: Use `print()` statements for debugging
3. **Simulator Menu**: Device → Shake for debugging options
4. **View Hierarchy**: Debug → View Debugging → Capture View Hierarchy

## Common iOS Development Commands

```bash
# Clean build folder
xcodebuild clean -project Game.xcodeproj

# Archive for distribution
xcodebuild archive -scheme Game -project Game.xcodeproj -archivePath build/Game.xcarchive

# Export IPA file
xcodebuild -exportArchive -archivePath build/Game.xcarchive -exportPath build/ -exportOptionsPlist exportOptions.plist

# List all schemes
xcodebuild -list -project Game.xcodeproj

# Show build settings
xcodebuild -showBuildSettings -scheme Game -project Game.xcodeproj
```

# Setup for CICD

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

6. **Local Development Issues**
   - **Simulator Not Found**: Update Xcode or install additional simulators
   - **Build Failures**: Clean build folder with `Cmd + Shift + K` in Xcode
   - **Signing Errors**: Check Apple Developer account and certificate status
   - **Fastlane Errors**: Run `bundle install` to update dependencies

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