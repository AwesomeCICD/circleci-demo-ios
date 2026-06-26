import Testing
import Foundation
@testable import StoreUpdaterCore

struct PackagerTests {
    /// Creates an isolated temp root with a `firmware` dir containing the given files.
    private func makeFirmware(_ files: [String: String]) throws -> (root: URL, firmware: URL) {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("store-updater-tests-\(UUID().uuidString)", isDirectory: true)
        let firmware = root.appendingPathComponent("firmware", isDirectory: true)
        try FileManager.default.createDirectory(at: firmware, withIntermediateDirectories: true)
        for (name, contents) in files {
            try Data(contents.utf8).write(to: firmware.appendingPathComponent(name))
        }
        return (root, firmware)
    }

    @Test func packageProducesManifestForEveryFile() throws {
        let (root, firmware) = try makeFirmware([
            "oven-controller.bin": "controller-payload",
            "recipe-pack.json": "{\"latte\":true}",
            "bootloader.sig": "signature-bytes",
        ])
        defer { try? FileManager.default.removeItem(at: root) }
        let image = root.appendingPathComponent("image", isDirectory: true)
        let manifest = try Packager().package(
            firmwareDir: firmware, into: image,
            product: "p", version: "3.4.1", deviceModel: "Mastrena-II"
        )
        #expect(manifest.artifacts.count == 3)
        #expect(FileManager.default.fileExists(
            atPath: image.appendingPathComponent("manifest.json").path))
    }

    @Test func verifySucceedsForCleanImage() throws {
        let (root, firmware) = try makeFirmware(["a.bin": "aaa", "b.bin": "bbb"])
        defer { try? FileManager.default.removeItem(at: root) }
        let image = root.appendingPathComponent("image", isDirectory: true)
        try Packager().package(firmwareDir: firmware, into: image,
                               product: "p", version: "1.0.0", deviceModel: "m")
        #expect(throws: Never.self) {
            try Packager().verify(stagingDir: image)
        }
    }

    @Test func verifyDetectsTampering() throws {
        let (root, firmware) = try makeFirmware(["a.bin": "original"])
        defer { try? FileManager.default.removeItem(at: root) }
        let image = root.appendingPathComponent("image", isDirectory: true)
        try Packager().package(firmwareDir: firmware, into: image,
                               product: "p", version: "1.0.0", deviceModel: "m")
        // Corrupt the staged payload after the manifest was written.
        try Data("corrupted".utf8).write(to: image.appendingPathComponent("payload/a.bin"))
        #expect(throws: UpdaterError.self) {
            try Packager().verify(stagingDir: image)
        }
    }

    @Test func verifyDetectsMissingArtifact() throws {
        let (root, firmware) = try makeFirmware(["a.bin": "x", "b.bin": "y"])
        defer { try? FileManager.default.removeItem(at: root) }
        let image = root.appendingPathComponent("image", isDirectory: true)
        try Packager().package(firmwareDir: firmware, into: image,
                               product: "p", version: "1.0.0", deviceModel: "m")
        try FileManager.default.removeItem(at: image.appendingPathComponent("payload/b.bin"))
        #expect(throws: UpdaterError.self) {
            try Packager().verify(stagingDir: image)
        }
    }

    @Test func packageRejectsEmptyFirmwareDir() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("store-updater-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let empty = root.appendingPathComponent("empty", isDirectory: true)
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        let image = root.appendingPathComponent("image", isDirectory: true)
        #expect(throws: UpdaterError.self) {
            try Packager().package(firmwareDir: empty, into: image,
                                   product: "p", version: "1", deviceModel: "m")
        }
    }
}
