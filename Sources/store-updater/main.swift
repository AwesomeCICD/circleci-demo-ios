import Foundation
import StoreUpdaterCore

func printUsage() {
    let usage = """
    store-updater — Starbucks in-store device update packager (CircleCI demo)

    USAGE:
      store-updater package --firmware <dir> --out <dir> [--version <v>] [--device <model>]
      store-updater verify  --image <dir>
      store-updater version

    COMMANDS:
      package   Build a USB recovery image from a firmware directory and write a
                checksummed manifest.json — the artifact a store manager flashes
                when an over-the-air update fails.
      verify    Re-check every file on an image against its manifest (hash check).
      version   Print the tool version.
    """
    FileHandle.standardError.write(Data((usage + "\n").utf8))
}

func value(for flag: String, in args: [String]) -> String? {
    guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
    return args[i + 1]
}

let args = Array(CommandLine.arguments.dropFirst())
guard let command = args.first else { printUsage(); exit(2) }

do {
    switch command {
    case "version", "--version", "-v":
        print("store-updater \(Version.current)")

    case "package":
        guard let firmware = value(for: "--firmware", in: args),
              let out = value(for: "--out", in: args) else {
            printUsage(); exit(2)
        }
        let manifest = try Packager().package(
            firmwareDir: URL(fileURLWithPath: firmware),
            into: URL(fileURLWithPath: out),
            product: "Starbucks Store Device Update",
            version: value(for: "--version", in: args) ?? Version.current,
            deviceModel: value(for: "--device", in: args) ?? "Mastrena-II"
        )
        print("Built update image v\(manifest.version) for \(manifest.deviceModel):")
        for a in manifest.artifacts {
            print("  - \(a.name)  (\(a.sizeBytes) bytes)  sha256=\(a.sha256.prefix(16))…")
        }
        print("Image written to \(out)")

    case "verify":
        guard let image = value(for: "--image", in: args) else { printUsage(); exit(2) }
        try Packager().verify(stagingDir: URL(fileURLWithPath: image))
        print("OK — every artifact matches the manifest. Safe to flash.")

    default:
        printUsage(); exit(2)
    }
} catch let error as UpdaterError {
    FileHandle.standardError.write(Data(("error: " + error.description + "\n").utf8))
    exit(1)
} catch {
    FileHandle.standardError.write(Data(("error: \(error)\n").utf8))
    exit(1)
}
