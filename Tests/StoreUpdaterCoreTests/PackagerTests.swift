import XCTest
@testable import StoreUpdaterCore

final class PackagerTests: XCTestCase {
    private var tmp: URL!

    override func setUpWithError() throws {
        tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("store-updater-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmp)
    }

    private func makeFirmware(_ files: [String: String]) throws -> URL {
        let dir = tmp.appendingPathComponent("firmware", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for (name, contents) in files {
            try Data(contents.utf8).write(to: dir.appendingPathComponent(name))
        }
        return dir
    }

    func testPackageProducesManifestForEveryFile() throws {
        let firmware = try makeFirmware([
            "oven-controller.bin": "controller-payload",
            "recipe-pack.json": "{\"latte\":true}",
            "bootloader.sig": "signature-bytes",
        ])
        let image = tmp.appendingPathComponent("image", isDirectory: true)
        let manifest = try Packager().package(
            firmwareDir: firmware, into: image,
            product: "p", version: "3.4.1", deviceModel: "Mastrena-II"
        )
        XCTAssertEqual(manifest.artifacts.count, 3)
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: image.appendingPathComponent("manifest.json").path))
    }

    func testVerifySucceedsForCleanImage() throws {
        let firmware = try makeFirmware(["a.bin": "aaa", "b.bin": "bbb"])
        let image = tmp.appendingPathComponent("image", isDirectory: true)
        try Packager().package(firmwareDir: firmware, into: image,
                               product: "p", version: "1.0.0", deviceModel: "m")
        XCTAssertNoThrow(try Packager().verify(stagingDir: image))
    }

    func testVerifyDetectsTampering() throws {
        let firmware = try makeFirmware(["a.bin": "original"])
        let image = tmp.appendingPathComponent("image", isDirectory: true)
        try Packager().package(firmwareDir: firmware, into: image,
                               product: "p", version: "1.0.0", deviceModel: "m")
        // Corrupt the staged payload after the manifest was written.
        try Data("corrupted".utf8).write(to: image.appendingPathComponent("payload/a.bin"))
        XCTAssertThrowsError(try Packager().verify(stagingDir: image)) { error in
            guard case UpdaterError.checksumMismatch = error else {
                return XCTFail("expected checksumMismatch, got \(error)")
            }
        }
    }

    func testVerifyDetectsMissingArtifact() throws {
        let firmware = try makeFirmware(["a.bin": "x", "b.bin": "y"])
        let image = tmp.appendingPathComponent("image", isDirectory: true)
        try Packager().package(firmwareDir: firmware, into: image,
                               product: "p", version: "1.0.0", deviceModel: "m")
        try FileManager.default.removeItem(at: image.appendingPathComponent("payload/b.bin"))
        XCTAssertThrowsError(try Packager().verify(stagingDir: image)) { error in
            guard case UpdaterError.missingArtifact = error else {
                return XCTFail("expected missingArtifact, got \(error)")
            }
        }
    }

    func testPackageRejectsEmptyFirmwareDir() throws {
        let empty = tmp.appendingPathComponent("empty", isDirectory: true)
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        let image = tmp.appendingPathComponent("image", isDirectory: true)
        XCTAssertThrowsError(try Packager().package(
            firmwareDir: empty, into: image, product: "p", version: "1", deviceModel: "m"))
    }
}
