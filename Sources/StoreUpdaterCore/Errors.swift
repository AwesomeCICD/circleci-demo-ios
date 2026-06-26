import Foundation

public enum UpdaterError: Error, CustomStringConvertible, Equatable {
    case noFirmwareFiles(String)
    case missingManifest(String)
    case missingArtifact(String)
    case checksumMismatch(name: String, expected: String, actual: String)

    public var description: String {
        switch self {
        case .noFirmwareFiles(let path):
            return "No firmware files found in \(path)."
        case .missingManifest(let path):
            return "No manifest.json found in \(path)."
        case .missingArtifact(let name):
            return "Update image is missing an expected artifact: \(name)."
        case .checksumMismatch(let name, let expected, let actual):
            return "Checksum mismatch for \(name): expected \(expected), got \(actual)."
        }
    }
}
