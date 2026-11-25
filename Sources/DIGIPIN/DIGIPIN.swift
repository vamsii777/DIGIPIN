import Foundation

/// Errors that can occur during DIGIPIN encoding, decoding, or validation.
public enum DIGIPINError: Error, LocalizedError, Equatable, CustomStringConvertible, Sendable {
    /// The provided coordinates are non-finite or outside the official DIGIPIN bounds for India
    /// (latitude 2.5°N–38.5°N, longitude 63.5°E–99.5°E).
    case outOfBounds
    /// The provided DIGIPIN code is invalid or malformed.
    case invalidDIGIPIN
    /// An internal error occurred during grid calculation.
    case gridCalculationError

    public var description: String {
        switch self {
        case .outOfBounds:
            return "Coordinates are out of bounds for DIGIPIN (latitude 2.5...38.5, longitude 63.5...99.5)."
        case .invalidDIGIPIN:
            return "Invalid DIGIPIN code. Expected a continuous 10-character code using only approved characters (2-9, C, F, J, K, L, M, P, T)."
        case .gridCalculationError:
            return "Internal grid calculation error."
        }
    }

    public var errorDescription: String? {
        description
    }
}

/// Controls how DIGIPIN strings are validated during decoding and normalization.
public enum DIGIPINValidationMode: Equatable, Hashable, Sendable {
    /// Strict compliance with the India Post DIGIPIN Standard v2.0.0 (May 2026 Revision).
    ///
    /// Leading and trailing whitespace is trimmed and ASCII letters are uppercased.
    /// The resulting code must be a continuous 10-character string composed exclusively
    /// of approved DIGIPIN characters (`2-9`, `C`, `F`, `J`, `K`, `L`, `M`, `P`, `T`).
    /// Hyphens, interior spaces, and other punctuation are rejected.
    case strict

    /// Lenient mode for migrating legacy data and parsing formatted user input.
    ///
    /// In addition to canonical 10-character codes (`39J49LL8T4`), this mode accepts:
    /// - Official May 2026 `3-4-3` space-grouped display codes (`39J 49LL 8T4`)
    /// - Legacy March 2025 `3-3-4` hyphenated codes (`39J-49L-L8T4`)
    ///
    /// Arbitrary or malformed separator placements are still rejected.
    case lenient
}

/// Represents a geographic coordinate (latitude and longitude in EPSG:4326 / WGS84).
public struct Coordinate: Equatable, Hashable, Codable, CustomStringConvertible, Sendable {
    /// Latitude in decimal degrees (WGS84).
    public let latitude: Double
    /// Longitude in decimal degrees (WGS84).
    public let longitude: Double

    /// Creates a new coordinate.
    /// - Parameters:
    ///   - latitude: Latitude in decimal degrees.
    ///   - longitude: Longitude in decimal degrees.
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    public var description: String {
        "(lat: \(latitude), lon: \(longitude))"
    }
}

/// DIGIPIN encoder/decoder compliant with the India Post DIGIPIN Technical Specification
/// & Architecture Standard — Version 2.0.0 (May 2026 Standards Revision).
public struct DIGIPIN: Sendable {
    // MARK: - Constants

    /// The official 4x4 DIGIPIN grid used uniformly across all 10 levels.
    private static let grid: [[String]] = [
        ["F", "C", "9", "8"],
        ["J", "3", "2", "7"],
        ["K", "4", "5", "6"],
        ["L", "M", "P", "T"]
    ]

    /// The number of grid divisions per level.
    private static let divisions = 4

    /// The official EPSG:4326 bounding box for DIGIPIN (India & EEZ coverage).
    private struct Bounds {
        static let minLat: Double = 2.5
        static let maxLat: Double = 38.5
        static let minLon: Double = 63.5
        static let maxLon: Double = 99.5
    }

    /// The number of levels (and characters) in a canonical DIGIPIN code.
    private static let codeLength = 10

    /// Creates a new DIGIPIN encoder/decoder.
    public init() {}

    // MARK: - Encoding

    /// Generates a canonical 10-character DIGIPIN code for the given coordinate.
    /// - Parameter coordinate: The coordinate to encode.
    /// - Returns: A continuous 10-character uppercase DIGIPIN code (e.g. `"39J49LL8T4"`).
    /// - Throws: `DIGIPINError.outOfBounds` if the coordinate is non-finite or outside India's DIGIPIN bounds.
    public func generateDIGIPIN(for coordinate: Coordinate) throws -> String {
        try generateDIGIPIN(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    /// Generates a canonical 10-character DIGIPIN code for the given latitude and longitude.
    /// - Parameters:
    ///   - latitude: Latitude in decimal degrees (`2.5...38.5`).
    ///   - longitude: Longitude in decimal degrees (`63.5...99.5`).
    /// - Returns: A continuous 10-character uppercase DIGIPIN code without hyphens or spaces (e.g. `"39J49LL8T4"`).
    /// - Throws: `DIGIPINError.outOfBounds` if the coordinate is non-finite or outside India's DIGIPIN bounds.
    public func generateDIGIPIN(latitude: Double, longitude: Double) throws -> String {
        guard Self.isValidCoordinate(latitude: latitude, longitude: longitude) else {
            throw DIGIPINError.outOfBounds
        }

        var minLat = Bounds.minLat
        var maxLat = Bounds.maxLat
        var minLon = Bounds.minLon
        var maxLon = Bounds.maxLon

        var code = ""
        code.reserveCapacity(Self.codeLength)

        for _ in 1...Self.codeLength {
            let latDiv = (maxLat - minLat) / Double(Self.divisions)
            let lonDiv = (maxLon - minLon) / Double(Self.divisions)

            // Reversed row logic per official specification (§4.3 & §4.4)
            let row = max(0, min(3, 3 - Int(floor((latitude - minLat) / latDiv))))
            let col = max(0, min(3, Int(floor((longitude - minLon) / lonDiv))))

            code += Self.grid[row][col]

            // Update bounds for next level
            let newMaxLat = minLat + latDiv * Double(4 - row)
            let newMinLat = minLat + latDiv * Double(3 - row)
            minLat = newMinLat
            maxLat = newMaxLat
            minLon = minLon + lonDiv * Double(col)
            maxLon = minLon + lonDiv
        }

        return code
    }

    // MARK: - Decoding

    /// Decodes a DIGIPIN code back to the central geographic coordinate of its grid cell.
    /// - Parameters:
    ///   - digiPin: The DIGIPIN code to decode. Input is trimmed of leading/trailing whitespace
    ///     and matched case-insensitively.
    ///   - mode: Validation mode. Defaults to `.strict` (May 2026 v2.0.0 standard: continuous
    ///     10-character string only; hyphens and interior spaces rejected). Pass `.lenient`
    ///     to also accept official `3-4-3` space-grouped display strings and legacy `3-3-4` hyphenated codes.
    /// - Returns: The central coordinate of the DIGIPIN cell.
    /// - Throws: `DIGIPINError.invalidDIGIPIN` if the code is malformed or contains invalid characters.
    public func coordinate(
        from digiPin: String,
        mode: DIGIPINValidationMode = .strict
    ) throws -> Coordinate {
        let cells = try Self.parseGridCells(from: digiPin, mode: mode)

        var minLat = Bounds.minLat
        var maxLat = Bounds.maxLat
        var minLon = Bounds.minLon
        var maxLon = Bounds.maxLon

        for cell in cells {
            let latDiv = (maxLat - minLat) / Double(Self.divisions)
            let lonDiv = (maxLon - minLon) / Double(Self.divisions)

            let lat1 = maxLat - latDiv * Double(cell.row + 1)
            let lat2 = maxLat - latDiv * Double(cell.row)
            let lon1 = minLon + lonDiv * Double(cell.col)
            let lon2 = minLon + lonDiv * Double(cell.col + 1)

            minLat = lat1
            maxLat = lat2
            minLon = lon1
            maxLon = lon2
        }

        let centerLat = (minLat + maxLat) / 2.0
        let centerLon = (minLon + maxLon) / 2.0
        return Coordinate(latitude: centerLat, longitude: centerLon)
    }

    // MARK: - Validation, Normalization & Display Formatting

    /// Returns whether the provided string is a valid DIGIPIN under the specified validation mode.
    /// - Parameters:
    ///   - digiPin: The candidate DIGIPIN string.
    ///   - mode: Validation mode (defaults to `.strict`, May 2026 v2.0.0 standard).
    /// - Returns: `true` if valid; otherwise `false`.
    public static func isValid(
        _ digiPin: String,
        mode: DIGIPINValidationMode = .strict
    ) -> Bool {
        (try? parseCanonicalBytes(from: digiPin, mode: mode)) != nil
    }

    /// Normalizes a DIGIPIN string into the canonical May 2026 v2.0.0 continuous 10-character uppercase format.
    ///
    /// Useful for migrating stored legacy `3-3-4` hyphenated codes (`39J-49L-L8T4`) or parsing
    /// `3-4-3` space-formatted display strings (`39J 49LL 8T4`) into canonical form (`39J49LL8T4`).
    /// - Parameters:
    ///   - digiPin: The DIGIPIN string to normalize.
    ///   - mode: Validation mode (defaults to `.lenient` to support legacy/display migration).
    /// - Returns: Canonical 10-character uppercase DIGIPIN string.
    /// - Throws: `DIGIPINError.invalidDIGIPIN` if the input is invalid under `mode`.
    public static func normalize(
        _ digiPin: String,
        mode: DIGIPINValidationMode = .lenient
    ) throws -> String {
        let bytes = try parseCanonicalBytes(from: digiPin, mode: mode)
        return String(decoding: bytes, as: UTF8.self)
    }

    /// Formats a DIGIPIN code into the official May 2026 §2(c) `3-4-3` space-separated display format.
    ///
    /// Example: `"39J49LL8T4"` → `"39J 49LL 8T4"`.
    ///
    /// > Important: Per the India Post DIGIPIN Standard (May 2026), space-grouped formatting is
    /// > intended solely for human-readable UI display. Always store and transmit the continuous
    /// > 10-character canonical string in APIs and databases.
    /// - Parameters:
    ///   - digiPin: The DIGIPIN code to format.
    ///   - mode: Validation mode used to validate the input (defaults to `.strict`).
    /// - Returns: A `3-4-3` space-grouped uppercase string.
    /// - Throws: `DIGIPINError.invalidDIGIPIN` if the input is invalid under `mode`.
    public static func formatForDisplay(
        _ digiPin: String,
        mode: DIGIPINValidationMode = .strict
    ) throws -> String {
        let bytes = try parseCanonicalBytes(from: digiPin, mode: mode)
        var formatted = [UInt8]()
        formatted.reserveCapacity(12)
        formatted.append(contentsOf: bytes[0..<3])
        formatted.append(0x20) // ' '
        formatted.append(contentsOf: bytes[3..<7])
        formatted.append(0x20) // ' '
        formatted.append(contentsOf: bytes[7..<10])
        return String(decoding: formatted, as: UTF8.self)
    }

    // MARK: - Distance

    /// Calculates the great-circle distance (in kilometers) between two coordinates using the haversine formula.
    /// - Parameters:
    ///   - from: The starting coordinate.
    ///   - to: The ending coordinate.
    /// - Returns: The distance in kilometers.
    /// - Complexity: O(1) time and space.
    public static func distance(from: Coordinate, to: Coordinate) -> Double {
        let earthRadiusKm = 6371.0088
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180
        let dLat = lat2 - lat1
        let dLon = lon2 - lon1
        let sinDLat = sin(dLat / 2)
        let sinDLon = sin(dLon / 2)
        let rawA = sinDLat * sinDLat + cos(lat1) * cos(lat2) * sinDLon * sinDLon
        let a = min(1.0, max(0.0, rawA))
        let c = 2 * atan2(sqrt(a), sqrt(1.0 - a))
        return earthRadiusKm * c
    }

    /// Calculates the great-circle distance (in kilometers) between two DIGIPIN codes.
    /// - Parameters:
    ///   - fromPin: The starting DIGIPIN code.
    ///   - toPin: The ending DIGIPIN code.
    ///   - mode: Validation mode (defaults to `.strict`).
    /// - Throws: `DIGIPINError.invalidDIGIPIN` if either code is invalid.
    /// - Returns: The distance in kilometers.
    /// - Complexity: O(1) time and space (fixed 10-level code).
    public func distance(
        from fromPin: String,
        to toPin: String,
        mode: DIGIPINValidationMode = .strict
    ) throws -> Double {
        let fromCoord = try coordinate(from: fromPin, mode: mode)
        let toCoord = try coordinate(from: toPin, mode: mode)
        return Self.distance(from: fromCoord, to: toCoord)
    }

    // MARK: - Bulk Operations

    /// Encodes an array of coordinates to canonical 10-character DIGIPIN codes.
    /// - Parameter coordinates: Array of coordinates to encode.
    /// - Returns: Array of results, each containing a DIGIPIN code or an error.
    public func bulkEncode(_ coordinates: [Coordinate]) -> [Result<String, DIGIPINError>] {
        coordinates.map { coordinate in
            do {
                return .success(try generateDIGIPIN(for: coordinate))
            } catch let error as DIGIPINError {
                return .failure(error)
            } catch {
                return .failure(.gridCalculationError)
            }
        }
    }

    /// Decodes an array of DIGIPIN codes to coordinates.
    /// - Parameters:
    ///   - digiPins: Array of DIGIPIN codes to decode.
    ///   - mode: Validation mode (defaults to `.strict`).
    /// - Returns: Array of results, each containing a Coordinate or an error.
    public func bulkDecode(
        _ digiPins: [String],
        mode: DIGIPINValidationMode = .strict
    ) -> [Result<Coordinate, DIGIPINError>] {
        digiPins.map { pin in
            do {
                return .success(try coordinate(from: pin, mode: mode))
            } catch let error as DIGIPINError {
                return .failure(error)
            } catch {
                return .failure(.gridCalculationError)
            }
        }
    }

    // MARK: - Private Helpers

    /// Checks if the coordinate is finite and within the official DIGIPIN bounds.
    private static func isValidCoordinate(latitude: Double, longitude: Double) -> Bool {
        latitude.isFinite && longitude.isFinite &&
        latitude >= Bounds.minLat && latitude <= Bounds.maxLat &&
        longitude >= Bounds.minLon && longitude <= Bounds.maxLon
    }

    /// Maps an uppercase ASCII byte to its `(row, col)` position in `DIGIPIN.grid` in O(1) time.
    private static func gridPosition(for uppercaseASCII: UInt8) -> (row: Int, col: Int)? {
        switch uppercaseASCII {
        case UInt8(ascii: "F"): return (0, 0)
        case UInt8(ascii: "C"): return (0, 1)
        case UInt8(ascii: "9"): return (0, 2)
        case UInt8(ascii: "8"): return (0, 3)
        case UInt8(ascii: "J"): return (1, 0)
        case UInt8(ascii: "3"): return (1, 1)
        case UInt8(ascii: "2"): return (1, 2)
        case UInt8(ascii: "7"): return (1, 3)
        case UInt8(ascii: "K"): return (2, 0)
        case UInt8(ascii: "4"): return (2, 1)
        case UInt8(ascii: "5"): return (2, 2)
        case UInt8(ascii: "6"): return (2, 3)
        case UInt8(ascii: "L"): return (3, 0)
        case UInt8(ascii: "M"): return (3, 1)
        case UInt8(ascii: "P"): return (3, 2)
        case UInt8(ascii: "T"): return (3, 3)
        default: return nil
        }
    }

    /// Converts an ASCII lowercase letter (`a`–`z`) to uppercase (`A`–`Z`); leaves other bytes unchanged.
    @inline(__always)
    private static func uppercaseASCII(_ byte: UInt8) -> UInt8 {
        (byte >= 0x61 && byte <= 0x7A) ? (byte - 0x20) : byte
    }

    /// Validates and extracts the 10 canonical uppercase ASCII bytes from `digiPin`.
    private static func parseCanonicalBytes(
        from digiPin: String,
        mode: DIGIPINValidationMode
    ) throws -> [UInt8] {
        let trimmed = digiPin.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawBytes = Array(trimmed.utf8)

        let candidateBytes: [UInt8]
        switch rawBytes.count {
        case Self.codeLength:
            candidateBytes = rawBytes
        case 12 where mode == .lenient:
            // Official May 2026 display format: 3-4-3 separated by single spaces ("39J 49LL 8T4")
            let isDisplaySpaced = rawBytes[3] == 0x20 && rawBytes[8] == 0x20
            // Legacy March 2025 format: 3-3-4 separated by single hyphens ("39J-49L-L8T4")
            let isLegacyHyphenated = rawBytes[3] == 0x2D && rawBytes[7] == 0x2D

            if isDisplaySpaced {
                candidateBytes = Array(rawBytes[0..<3]) + Array(rawBytes[4..<8]) + Array(rawBytes[9..<12])
            } else if isLegacyHyphenated {
                candidateBytes = Array(rawBytes[0..<3]) + Array(rawBytes[4..<7]) + Array(rawBytes[8..<12])
            } else {
                throw DIGIPINError.invalidDIGIPIN
            }
        default:
            throw DIGIPINError.invalidDIGIPIN
        }

        var canonical = [UInt8]()
        canonical.reserveCapacity(Self.codeLength)
        for byte in candidateBytes {
            let upper = uppercaseASCII(byte)
            guard gridPosition(for: upper) != nil else {
                throw DIGIPINError.invalidDIGIPIN
            }
            canonical.append(upper)
        }
        return canonical
    }

    /// Validates and extracts the 10 `(row, col)` grid positions from `digiPin`.
    private static func parseGridCells(
        from digiPin: String,
        mode: DIGIPINValidationMode
    ) throws -> [(row: Int, col: Int)] {
        let bytes = try parseCanonicalBytes(from: digiPin, mode: mode)
        var cells = [(row: Int, col: Int)]()
        cells.reserveCapacity(Self.codeLength)
        for byte in bytes {
            guard let pos = gridPosition(for: byte) else {
                throw DIGIPINError.invalidDIGIPIN
            }
            cells.append(pos)
        }
        return cells
    }
}
