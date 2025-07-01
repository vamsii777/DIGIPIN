import XCTest

final class DIGIPINCLITests: XCTestCase {
    private var cliPath: String {
        // Assumes the CLI binary is built at .build/debug/digipin-cli
        let root = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return root.appendingPathComponent(".build/debug/digipin-cli").path
    }

    private func runCLI(_ args: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    func testEncode() throws {
        guard FileManager.default.isExecutableFile(atPath: cliPath) else {
            throw XCTSkip("digipin-cli binary not found. Build with `swift build` first.")
        }
        let output = try runCLI(["encode", "12.9716", "77.5946"])
        XCTAssertEqual(output, "4P3-JK8-52C9")
    }

    func testDecode() throws {
        guard FileManager.default.isExecutableFile(atPath: cliPath) else {
            throw XCTSkip("digipin-cli binary not found. Build with `swift build` first.")
        }
        let output = try runCLI(["decode", "4P3-JK8-52C9"])
        XCTAssertTrue(output.contains(","))
        // Optionally check for expected lat/lon values
    }

    func testDistance() throws {
        guard FileManager.default.isExecutableFile(atPath: cliPath) else {
            throw XCTSkip("digipin-cli binary not found. Build with `swift build` first.")
        }
        let output = try runCLI(["distance", "4P3-JK8-52C9", "39J-49L-L8T4"])
        XCTAssertTrue(output.hasSuffix("km"))
        // Optionally check for expected distance value
    }
} 