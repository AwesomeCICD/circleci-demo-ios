// swift-tools-version: 5.9
import PackageDescription

// Starbucks in-store device update packager.
//
// This is a NATIVE macOS tool (not an iOS app and not a Docker image): it builds
// the USB recovery image / update bundle that store managers flash to in-store
// hardware (e.g. Mastrena ovens) when an over-the-air update fails. The shipped
// artifact is a signed, notarized .dmg.
let package = Package(
    name: "StoreDeviceUpdater",
    platforms: [.macOS(.v12)],
    targets: [
        .target(name: "StoreUpdaterCore"),
        .executableTarget(
            name: "store-updater",
            dependencies: ["StoreUpdaterCore"]
        ),
        .testTarget(
            name: "StoreUpdaterCoreTests",
            dependencies: ["StoreUpdaterCore"]
        ),
    ]
)
