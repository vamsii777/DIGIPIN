import Foundation
import DIGIPIN
import ArgumentParser

struct DigipinCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "digipin",
        abstract: "DIGIPIN CLI: Encode, decode, and compute distances for India Post DIGIPIN codes.",
        subcommands: [Encode.self, Decode.self, Distance.self],
        defaultSubcommand: Encode.self
    )

    struct Encode: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Encode latitude and longitude to a DIGIPIN code.")
        @Argument(help: "Latitude in decimal degrees.") var latitude: Double
        @Argument(help: "Longitude in decimal degrees.") var longitude: Double
        func run() throws {
            let digipin = DIGIPIN()
            let code = try digipin.generateDIGIPIN(latitude: latitude, longitude: longitude)
            print(code)
        }
    }

    struct Decode: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Decode a DIGIPIN code to latitude and longitude.")
        @Argument(help: "DIGIPIN code (with or without hyphens).") var code: String
        func run() throws {
            let digipin = DIGIPIN()
            let coord = try digipin.coordinate(from: code)
            print(String(format: "%.6f, %.6f", coord.latitude, coord.longitude))
        }
    }

    struct Distance: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Compute the distance (in km) between two DIGIPIN codes.")
        @Argument(help: "First DIGIPIN code.") var code1: String
        @Argument(help: "Second DIGIPIN code.") var code2: String
        func run() throws {
            let digipin = DIGIPIN()
            let dist = try digipin.distance(from: code1, to: code2)
            print(String(format: "%.2f km", dist))
        }
    }
}

DigipinCLI.main() 