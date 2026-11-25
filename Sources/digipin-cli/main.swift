import Foundation
import DIGIPIN
import ArgumentParser

struct DigipinCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "digipin",
        abstract: "DIGIPIN CLI: Encode, decode, normalize, and compute distances for India Post DIGIPIN codes (May 2026 v2.0.0 standard).",
        subcommands: [Encode.self, Decode.self, Distance.self, Normalize.self],
        defaultSubcommand: Encode.self
    )

    struct Encode: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Encode latitude and longitude to a canonical 10-character DIGIPIN code."
        )

        @Argument(help: "Latitude in decimal degrees (2.5 to 38.5).")
        var latitude: Double

        @Argument(help: "Longitude in decimal degrees (63.5 to 99.5).")
        var longitude: Double

        @Flag(name: .long, help: "Format output using the official May 2026 3-4-3 spaced display grouping (for display only).")
        var display: Bool = false

        func run() throws {
            let digipin = DIGIPIN()
            let code = try digipin.generateDIGIPIN(latitude: latitude, longitude: longitude)
            if display {
                print(try DIGIPIN.formatForDisplay(code))
            } else {
                print(code)
            }
        }
    }

    struct Decode: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Decode a DIGIPIN code to its central latitude and longitude."
        )

        @Argument(help: "DIGIPIN code (canonical 10-character continuous string by default).")
        var code: String

        @Flag(name: .long, help: "Accept legacy 3-3-4 hyphenated and official 3-4-3 spaced display inputs.")
        var lenient: Bool = false

        func run() throws {
            let digipin = DIGIPIN()
            let mode: DIGIPINValidationMode = lenient ? .lenient : .strict
            let coord = try digipin.coordinate(from: code, mode: mode)
            print(String(format: "%.6f, %.6f", coord.latitude, coord.longitude))
        }
    }

    struct Distance: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Compute the great-circle distance (in km) between two DIGIPIN codes."
        )

        @Argument(help: "First DIGIPIN code.")
        var code1: String

        @Argument(help: "Second DIGIPIN code.")
        var code2: String

        @Flag(name: .long, help: "Accept legacy 3-3-4 hyphenated and official 3-4-3 spaced display inputs.")
        var lenient: Bool = false

        func run() throws {
            let digipin = DIGIPIN()
            let mode: DIGIPINValidationMode = lenient ? .lenient : .strict
            let dist = try digipin.distance(from: code1, to: code2, mode: mode)
            print(String(format: "%.2f km", dist))
        }
    }

    struct Normalize: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Normalize a legacy hyphenated (3-3-4), display spaced (3-4-3), or lowercase DIGIPIN to canonical 10-character uppercase format."
        )

        @Argument(help: "DIGIPIN code to normalize.")
        var code: String

        @Flag(name: .long, help: "Format normalized output using the official May 2026 3-4-3 spaced display grouping.")
        var display: Bool = false

        func run() throws {
            let canonical = try DIGIPIN.normalize(code, mode: .lenient)
            if display {
                print(try DIGIPIN.formatForDisplay(canonical))
            } else {
                print(canonical)
            }
        }
    }
}

DigipinCLI.main()
