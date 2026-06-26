import Foundation
import CryptoKit

public enum Hashing {
    /// SHA-256 of a file's contents as lowercase hex. This is the same integrity
    /// check the in-store USB recovery flow relies on before flashing a device.
    public static func sha256(ofFileAt url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
