import Foundation

/// Errors that can occur during DIGIPIN encoding or decoding.
public enum DIGIPINError: Error, Equatable, CustomStringConvertible {
    /// The provided coordinates are outside the supported bounds for India.
    case outOfBounds
    /// The provided DIGIPIN code is invalid or malformed.
    case invalidDIGIPIN
    /// An internal error occurred during grid calculation.
    case gridCalculationError

    public var description: String {
        switch self {
        case .outOfBounds:
            return "Coordinates are out of bounds for DIGIPIN."
        case .invalidDIGIPIN:
            return "Invalid DIGIPIN code."
        case .gridCalculationError:
            return "Internal grid calculation error."
        }
    }
}

/// Represents a geographic coordinate (latitude and longitude).
public struct Coordinate: Equatable, CustomStringConvertible {
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

/// DIGIPIN encoder/decoder for India Post's Digital Postal Index Number system.
public struct DIGIPIN {
    // MARK: - Constants

    /// The official 4x4 DIGIPIN grid used at all levels.
    private static let grid: [[String]] = [
        ["F", "C", "9", "8"],
        ["J", "3", "2", "7"],
        ["K", "4", "5", "6"],
        ["L", "M", "P", "T"]
    ]
    
    /// The number of grid divisions per level.
    private static let divisions = 4

    /// The official bounding box for DIGIPIN (India coverage).
    private struct Bounds {
        static let minLat: Double = 2.5
        static let maxLat: Double = 38.5
        static let minLon: Double = 63.5
        static let maxLon: Double = 99.5
    }

    /// The number of levels in a DIGIPIN code.
    private static let codeLength = 10

    /// Hyphen positions for formatting (after 3rd and 6th character).
    private static let hyphenPositions: Set<Int> = [3, 6]

    /// Creates a new DIGIPIN encoder/decoder.
    public init() {}
    
    // MARK: - Public API
    
    /// Generates a DIGIPIN code for the given coordinate.
    /// - Parameter coordinate: The coordinate to encode.
    /// - Returns: A 10-character DIGIPIN code (with hyphens for readability).
    /// - Throws: `DIGIPINError.outOfBounds` if the coordinate is outside India.
    public func generateDIGIPIN(for coordinate: Coordinate) throws -> String {
        try generateDIGIPIN(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    /// Generates a DIGIPIN code for the given latitude and longitude.
    /// - Parameters:
    ///   - latitude: Latitude in decimal degrees.
    ///   - longitude: Longitude in decimal degrees.
    /// - Returns: A 10-character DIGIPIN code (with hyphens for readability).
    /// - Throws: `DIGIPINError.outOfBounds` if the coordinate is outside India.
    public func generateDIGIPIN(latitude: Double, longitude: Double) throws -> String {
        guard Self.isValidCoordinate(latitude: latitude, longitude: longitude) else {
            throw DIGIPINError.outOfBounds
        }
        var minLat = Bounds.minLat
        var maxLat = Bounds.maxLat
        var minLon = Bounds.minLon
        var maxLon = Bounds.maxLon
        var code = ""
        for level in 1...Self.codeLength {
            let latDiv = (maxLat - minLat) / Double(Self.divisions)
            let lonDiv = (maxLon - minLon) / Double(Self.divisions)
            let row = max(0, min(3, 3 - Int(floor((latitude - minLat) / latDiv))))
            let col = max(0, min(3, Int(floor((longitude - minLon) / lonDiv))))
            code += Self.grid[row][col]
            if Self.hyphenPositions.contains(level) && level != Self.codeLength {
                code += "-"
            }
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
    
    /// Decodes a DIGIPIN code back to its central geographic coordinate.
    /// - Parameter digiPin: The DIGIPIN code (with or without hyphens).
    /// - Returns: The central coordinate of the DIGIPIN cell.
    /// - Throws: `DIGIPINError.invalidDIGIPIN` if the code is malformed or contains invalid characters.
    public func coordinate(from digiPin: String) throws -> Coordinate {
        let cleanPin = digiPin.replacingOccurrences(of: "-", with: "")
        guard cleanPin.count == Self.codeLength else { throw DIGIPINError.invalidDIGIPIN }
        var minLat = Bounds.minLat
        var maxLat = Bounds.maxLat
        var minLon = Bounds.minLon
        var maxLon = Bounds.maxLon
        for i in 0..<Self.codeLength {
            let ch = String(cleanPin[cleanPin.index(cleanPin.startIndex, offsetBy: i)])
            var found = false
            var ri = -1, ci = -1
            for r in 0..<Self.divisions {
                for c in 0..<Self.divisions {
                    if Self.grid[r][c] == ch {
                        ri = r
                        ci = c
                        found = true
                        break
                    }
                }
                if found { break }
            }
            if !found { throw DIGIPINError.invalidDIGIPIN }
            let latDiv = (maxLat - minLat) / Double(Self.divisions)
            let lonDiv = (maxLon - minLon) / Double(Self.divisions)
            let lat1 = maxLat - latDiv * Double(ri + 1)
            let lat2 = maxLat - latDiv * Double(ri)
            let lon1 = minLon + lonDiv * Double(ci)
            let lon2 = minLon + lonDiv * Double(ci + 1)
            minLat = lat1
            maxLat = lat2
            minLon = lon1
            maxLon = lon2
        }
        let centerLat = (minLat + maxLat) / 2.0
        let centerLon = (minLon + maxLon) / 2.0
        return Coordinate(latitude: centerLat, longitude: centerLon)
    }

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
        let a = sin(dLat/2) * sin(dLat/2) + cos(lat1) * cos(lat2) * sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return earthRadiusKm * c
    }

    /// Calculates the great-circle distance (in kilometers) between two DIGIPIN codes.
    /// - Parameters:
    ///   - fromPin: The starting DIGIPIN code.
    ///   - toPin: The ending DIGIPIN code.
    /// - Throws: `DIGIPINError.invalidDIGIPIN` if either code is invalid.
    /// - Returns: The distance in kilometers.
    /// - Complexity: O(n) time, where n is the code length (default 10).
    public func distance(from fromPin: String, to toPin: String) throws -> Double {
        let fromCoord = try coordinate(from: fromPin)
        let toCoord = try coordinate(from: toPin)
        return Self.distance(from: fromCoord, to: toCoord)
    }

    /// Encodes an array of coordinates to DIGIPIN codes.
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
    /// - Parameter digiPins: Array of DIGIPIN codes to decode.
    /// - Returns: Array of results, each containing a Coordinate or an error.
    public func bulkDecode(_ digiPins: [String]) -> [Result<Coordinate, DIGIPINError>] {
        digiPins.map { pin in
            do {
                return .success(try coordinate(from: pin))
            } catch let error as DIGIPINError {
                return .failure(error)
            } catch {
                return .failure(.gridCalculationError)
            }
        }
    }

    // MARK: - Private Helpers

    /// Checks if the coordinate is within the official DIGIPIN bounds.
    private static func isValidCoordinate(latitude: Double, longitude: Double) -> Bool {
        latitude >= Bounds.minLat && latitude <= Bounds.maxLat &&
        longitude >= Bounds.minLon && longitude <= Bounds.maxLon
    }
}
