import Foundation

/// One firmware/payload file on a store update image, with the checksum a device
/// uses to confirm the file arrived intact.
public struct FirmwareArtifact: Codable, Equatable {
    public let name: String
    public let sizeBytes: Int
    public let sha256: String

    public init(name: String, sizeBytes: Int, sha256: String) {
        self.name = name
        self.sizeBytes = sizeBytes
        self.sha256 = sha256
    }
}

/// The manifest written onto every update image. A store manager's USB recovery
/// flow (and any OTA consumer) verifies the payload against this before applying.
public struct UpdateManifest: Codable, Equatable {
    public let product: String
    public let version: String
    public let deviceModel: String
    public let createdAt: String
    public let artifacts: [FirmwareArtifact]

    public init(product: String, version: String, deviceModel: String, createdAt: String, artifacts: [FirmwareArtifact]) {
        self.product = product
        self.version = version
        self.deviceModel = deviceModel
        self.createdAt = createdAt
        self.artifacts = artifacts
    }
}
