import XCTest

final class DIGIPINCLITests: XCTestCase {
    private var cliURL: URL {
        // Locate the built `digipin` executable in the same products directory as the test bundle.
        let bundleDir = Bundle(for: DIGIPINCLITests.self).bundleURL.deletingLastPathComponent()
        let siblingBinary = bundleDir.appendingPathComponent("digipin")
        if FileManager.default.isExecutableFile(atPath: siblingBinary.path) {
            return siblingBinary
        }

        // Fallback to .build/debug/digipin from repo root
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return root.appendingPathComponent(".build/debug/digipin")
    }

    private func runCLI(_ args: [String]) throws -> (exitCode: Int32, output: String) {
        let binaryURL = cliURL
        XCTAssertTrue(
            FileManager.default.isExecutableFile(atPath: binaryURL.path),
            "digipin executable not found at \(binaryURL.path)"
        )

        let process = Process()
        process.executableURL = binaryURL
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return (process.terminationStatus, output)
    }

    func testEncodeCanonicalAndDisplay() throws {
        let canonical = try runCLI(["encode", "12.9716", "77.5946"])
        XCTAssertEqual(canonical.exitCode, 0)
        XCTAssertEqual(canonical.output, "4P3JK852C9")

        let display = try runCLI(["encode", "--display", "12.9716", "77.5946"])
        XCTAssertEqual(display.exitCode, 0)
        XCTAssertEqual(display.output, "4P3 JK85 2C9")
    }

    func testDecodeStrictAndLenient() throws {
        let strict = try runCLI(["decode", "4P3JK852C9"])
        XCTAssertEqual(strict.exitCode, 0)
        XCTAssertEqual(strict.output, "12.971601, 77.594584")

        // Strict mode rejects legacy hyphenated input
        let strictLegacy = try runCLI(["decode", "4P3-JK8-52C9"])
        XCTAssertNotEqual(strictLegacy.exitCode, 0)

        // Lenient mode accepts legacy hyphenated and display spaced inputs
        let lenientLegacy = try runCLI(["decode", "--lenient", "4P3-JK8-52C9"])
        XCTAssertEqual(lenientLegacy.exitCode, 0)
        XCTAssertEqual(lenientLegacy.output, "12.971601, 77.594584")

        let lenientDisplay = try runCLI(["decode", "--lenient", "4P3 JK85 2C9"])
        XCTAssertEqual(lenientDisplay.exitCode, 0)
        XCTAssertEqual(lenientDisplay.output, "12.971601, 77.594584")
    }

    func testDistanceStrictAndLenient() throws {
        let strict = try runCLI(["distance", "4P3JK852C9", "39J49LL8T4"])
        XCTAssertEqual(strict.exitCode, 0)
        XCTAssertTrue(strict.output.hasSuffix("km"))

        let lenient = try runCLI(["distance", "--lenient", "4P3-JK8-52C9", "39J-49L-L8T4"])
        XCTAssertEqual(lenient.exitCode, 0)
        XCTAssertEqual(lenient.output, strict.output)
    }

    func testNormalize() throws {
        let canonical = try runCLI(["normalize", "39j-49l-l8t4"])
        XCTAssertEqual(canonical.exitCode, 0)
        XCTAssertEqual(canonical.output, "39J49LL8T4")

        let display = try runCLI(["normalize", "--display", "39J-49L-L8T4"])
        XCTAssertEqual(display.exitCode, 0)
        XCTAssertEqual(display.output, "39J 49LL 8T4")
    }
}
