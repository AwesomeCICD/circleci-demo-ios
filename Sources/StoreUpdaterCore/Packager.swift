import Foundation

/// Builds and verifies store update images.
///
/// `package` mirrors what the in-store utility does: format a clean staging area,
/// copy the firmware payload, and write a checksummed manifest. `verify` is the
/// hash check that protects a device from a corrupt or tampered image.
public struct Packager {
    public init() {}

    @discardableResult
    public func package(firmwareDir: URL,
                        into stagingDir: URL,
                        product: String,
                        version: String,
                        deviceModel: String,
                        now: Date = Date()) throws -> UpdateManifest {
        let fm = FileManager.default

        // "Format" the staging area so every image is built from a clean slate.
        if fm.fileExists(atPath: stagingDir.path) {
            try fm.removeItem(at: stagingDir)
        }
        let payloadDir = stagingDir.appendingPathComponent("payload", isDirectory: true)
        try fm.createDirectory(at: payloadDir, withIntermediateDirectories: true)

        let entries = try fm.contentsOfDirectory(at: firmwareDir,
                                                 includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
                                                 options: [.skipsHiddenFiles])
            .filter { (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        guard !entries.isEmpty else { throw UpdaterError.noFirmwareFiles(firmwareDir.path) }

        var artifacts: [FirmwareArtifact] = []
        for src in entries {
            let dest = payloadDir.appendingPathComponent(src.lastPathComponent)
            try fm.copyItem(at: src, to: dest)
            let size = (try? src.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            let sha = try Hashing.sha256(ofFileAt: dest)
            artifacts.append(FirmwareArtifact(name: src.lastPathComponent, sizeBytes: size, sha256: sha))
        }

        let manifest = UpdateManifest(product: product,
                                      version: version,
                                      deviceModel: deviceModel,
                                      createdAt: ISO8601DateFormatter().string(from: now),
                                      artifacts: artifacts)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(manifest).write(to: stagingDir.appendingPathComponent("manifest.json"))
        return manifest
    }

    /// Re-verify every artifact on a staged image against its manifest. If a file
    /// is missing or its checksum no longer matches, this fails loudly rather than
    /// letting a bad update reach a device.
    public func verify(stagingDir: URL) throws {
        let fm = FileManager.default
        let manifestURL = stagingDir.appendingPathComponent("manifest.json")
        guard fm.fileExists(atPath: manifestURL.path) else {
            throw UpdaterError.missingManifest(stagingDir.path)
        }
        let manifest = try JSONDecoder().decode(UpdateManifest.self, from: Data(contentsOf: manifestURL))
        let payloadDir = stagingDir.appendingPathComponent("payload", isDirectory: true)
        for artifact in manifest.artifacts {
            let file = payloadDir.appendingPathComponent(artifact.name)
            guard fm.fileExists(atPath: file.path) else {
                throw UpdaterError.missingArtifact(artifact.name)
            }
            let actual = try Hashing.sha256(ofFileAt: file)
            guard actual == artifact.sha256 else {
                throw UpdaterError.checksumMismatch(name: artifact.name, expected: artifact.sha256, actual: actual)
            }
        }
    }
}
