import XCTest
@testable import DIGIPIN

final class DIGIPINTests: XCTestCase {
    private var sut: DIGIPIN!

    override func setUp() {
        super.setUp()
        sut = DIGIPIN()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Official Golden Vectors (India Post DIGIPIN v2.0.0 - May 2026)

    func testOfficialGoldenVectors() throws {
        // Verified directly against official INDIAPOST-gov/digipin/src/digipin.js (v2.0.0)
        let vectors: [(name: String, lat: Double, lon: Double, expectedPin: String, expectedLat: Double, expectedLon: Double)] = [
            ("Dak Bhawan, New Delhi", 28.622788, 77.213033, "39J49LL8T4", 28.622793, 77.213049),
            ("Bangalore", 12.9716, 77.5946, "4P3JK852C9", 12.971601, 77.594584),
            ("Chennai (JSDoc example)", 13.11179621, 80.20264269, "4T396F42L7", 13.111780, 80.202635),
            ("Chennai (Swagger example)", 13.067526, 80.270956, "4T38MJK524", 13.067526, 80.270956),
            ("New Delhi", 28.6139, 77.2090, "39J438TJC7", 28.613901, 77.208998),
            ("Mumbai", 19.0760, 72.8777, "4FK5958823", 19.075983, 72.877707),
        ]

        for vector in vectors {
            let coordinate = Coordinate(latitude: vector.lat, longitude: vector.lon)
            let code = try sut.generateDIGIPIN(for: coordinate)
            XCTAssertEqual(code, vector.expectedPin, "Encode mismatch for \(vector.name)")
            XCTAssertEqual(code.count, 10, "Canonical DIGIPIN must be 10 characters for \(vector.name)")
            XCTAssertFalse(code.contains("-"), "Canonical DIGIPIN must not contain hyphens")
            XCTAssertFalse(code.contains(" "), "Canonical DIGIPIN must not contain spaces")

            let codeAlt = try sut.generateDIGIPIN(latitude: vector.lat, longitude: vector.lon)
            XCTAssertEqual(code, codeAlt)

            let decoded = try sut.coordinate(from: code)
            XCTAssertEqual(decoded.latitude, vector.expectedLat, accuracy: 0.000001, "Decode lat mismatch for \(vector.name)")
            XCTAssertEqual(decoded.longitude, vector.expectedLon, accuracy: 0.000001, "Decode lon mismatch for \(vector.name)")
        }
    }

    // MARK: - Boundary Corners & Grid-Line Tie-Breaking (§4.1 & §4.4)

    func testExactCornerBoundaries() throws {
        // SW corner (minLat, minLon) -> LLLLLLLLLL
        XCTAssertEqual(try sut.generateDIGIPIN(latitude: 2.5, longitude: 63.5), "LLLLLLLLLL")
        // NW corner (maxLat, minLon) -> top-most boundary clamps southward -> FFFFFFFFFF
        XCTAssertEqual(try sut.generateDIGIPIN(latitude: 38.5, longitude: 63.5), "FFFFFFFFFF")
        // SE corner (minLat, maxLon) -> right-most boundary clamps westward -> TTTTTTTTTT
        XCTAssertEqual(try sut.generateDIGIPIN(latitude: 2.5, longitude: 99.5), "TTTTTTTTTT")
        // NE corner (maxLat, maxLon) -> clamps southwestward -> 8888888888
        XCTAssertEqual(try sut.generateDIGIPIN(latitude: 38.5, longitude: 99.5), "8888888888")
    }

    func testGridLineTieBreakingRules() throws {
        // §4.4: Vertical grid lines -> eastward; horizontal grid lines -> northward;
        // intersections -> top-right (northeast) cell.
        XCTAssertEqual(try sut.generateDIGIPIN(latitude: 20.5, longitude: 81.5), "2LLLLLLLLL")
        XCTAssertEqual(try sut.generateDIGIPIN(latitude: 11.5, longitude: 72.5), "4LLLLLLLLL")
        XCTAssertEqual(try sut.generateDIGIPIN(latitude: 29.5, longitude: 90.5), "8LLLLLLLLL")
    }

    func testOutOfBoundsAndNonFiniteCoordinates() {
        let invalidCoordinates: [(Double, Double)] = [
            (2.4999999, 77.0),
            (38.5000001, 77.0),
            (20.0, 63.4999999),
            (20.0, 99.5000001),
            (40.0, 78.12351),
            (17.59551, 120.0),
            (-10.0, 77.0),
            (0.0, 0.0),
            (-0.0, 77.0),
            (.nan, 77.0),
            (20.0, .nan),
            (.infinity, 77.0),
            (-.infinity, 77.0),
            (20.0, .infinity),
            (20.0, -.infinity),
        ]

        for (lat, lon) in invalidCoordinates {
            XCTAssertThrowsError(try sut.generateDIGIPIN(latitude: lat, longitude: lon)) { error in
                XCTAssertEqual(error as? DIGIPINError, .outOfBounds)
            }
        }
    }

    // MARK: - Strict Decoding & Validation (May 2026 v2.0.0)

    func testStrictDecodeCaseInsensitivityAndWhitespaceTrimming() throws {
        let canonical = try sut.coordinate(from: "39J49LL8T4")
        let lower = try sut.coordinate(from: "39j49ll8t4")
        let mixed = try sut.coordinate(from: "39J49lL8t4")
        let padded = try sut.coordinate(from: "  \t39J49LL8T4\n ")
        let paddedLower = try sut.coordinate(from: "  39j49ll8t4  ")

        XCTAssertEqual(lower, canonical)
        XCTAssertEqual(mixed, canonical)
        XCTAssertEqual(padded, canonical)
        XCTAssertEqual(paddedLower, canonical)
    }

    func testStrictModeRejectsHyphensSpacesAndInvalidCharacters() {
        let invalidInStrict = [
            "",                     // Empty
            "   ",                  // Whitespace only
            "39J49LL8T",            // Too short (9)
            "39J49LL8T45",          // Too long (11)
            "39J-49L-L8T4",         // Legacy 3-3-4 hyphenated (forbidden in strict v2.0.0)
            "39J 49LL 8T4",         // Display 3-4-3 spaced (forbidden in strict v2.0.0)
            "39J 49L L8T4",         // 3-3-4 spaced
            "3-9-J-4-9-L-L-8-T-4",  // Scattered hyphens
            "---39J49LL8T4---",     // Leading/trailing hyphens
            "XXXX-XXXX-XX",         // Invalid letters + hyphens
            "09J49LL8T4",           // Forbidden '0'
            "19J49LL8T4",           // Forbidden '1'
            "A9J49LL8T4",           // Forbidden 'A'
            "B9J49LL8T4",           // Forbidden 'B'
            "D9J49LL8T4",           // Forbidden 'D'
            "E9J49LL8T4",           // Forbidden 'E'
            "G9J49LL8T4",           // Forbidden 'G' (removed from beta)
            "H9J49LL8T4",           // Forbidden 'H'
            "I9J49LL8T4",           // Forbidden 'I'
            "N9J49LL8T4",           // Forbidden 'N'
            "O9J49LL8T4",           // Forbidden 'O'
            "Q9J49LL8T4",           // Forbidden 'Q'
            "R9J49LL8T4",           // Forbidden 'R'
            "S9J49LL8T4",           // Forbidden 'S'
            "U9J49LL8T4",           // Forbidden 'U'
            "V9J49LL8T4",           // Forbidden 'V'
            "W9J49LL8T4",           // Forbidden 'W' (removed from beta)
            "X9J49LL8T4",           // Forbidden 'X' (removed from beta)
            "Y9J49LL8T4",           // Forbidden 'Y'
            "Z9J49LL8T4",           // Forbidden 'Z'
            "３９Ｊ４９ＬＬ８Ｔ４",    // Fullwidth Unicode lookalikes
            "39J49LL8T\u{0301}",    // Combining acute accent
            "39J49LL8ß",            // Non-ASCII sharp s (expands to SS in uppercased())
        ]

        for candidate in invalidInStrict {
            XCTAssertFalse(DIGIPIN.isValid(candidate, mode: .strict), "Expected strict isValid == false for '\(candidate)'")
            XCTAssertThrowsError(try sut.coordinate(from: candidate), "Expected strict decode failure for '\(candidate)'") { error in
                XCTAssertEqual(error as? DIGIPINError, .invalidDIGIPIN)
            }
        }
    }

    // MARK: - Lenient Mode, Normalization & Display Formatting

    func testLenientModeAcceptsCanonicalDisplayAndLegacyFormats() throws {
        let canonicalCoord = try sut.coordinate(from: "39J49LL8T4")

        // Canonical
        XCTAssertEqual(try sut.coordinate(from: "39J49LL8T4", mode: .lenient), canonicalCoord)
        // Official May 2026 display format (3-4-3 spaces)
        XCTAssertEqual(try sut.coordinate(from: "39J 49LL 8T4", mode: .lenient), canonicalCoord)
        XCTAssertEqual(try sut.coordinate(from: "  39j 49ll 8t4  ", mode: .lenient), canonicalCoord)
        // Legacy March 2025 format (3-3-4 hyphens)
        XCTAssertEqual(try sut.coordinate(from: "39J-49L-L8T4", mode: .lenient), canonicalCoord)
        XCTAssertEqual(try sut.coordinate(from: "  39j-49l-l8t4  ", mode: .lenient), canonicalCoord)

        // Malformed separator placements must STILL fail in lenient mode
        let malformedEvenInLenient = [
            "39J-49LL-8T4",        // Wrong hyphen grouping (3-4-3 with hyphens)
            "39J 49L L8T4",        // Wrong space grouping (3-3-4 with spaces)
            "39J-49L L8T4",        // Mixed separators
            "3-9J49LL8T4",         // Misplaced single hyphen
            "---39J49LL8T4---",    // Wrapping hyphens
            "39J--49L-L8T4",       // Double hyphen
            "39J  49LL 8T4",       // Double space
        ]

        for bad in malformedEvenInLenient {
            XCTAssertFalse(DIGIPIN.isValid(bad, mode: .lenient), "Expected lenient isValid == false for '\(bad)'")
            XCTAssertThrowsError(try sut.coordinate(from: bad, mode: .lenient)) { error in
                XCTAssertEqual(error as? DIGIPINError, .invalidDIGIPIN)
            }
        }
    }

    func testNormalizeAndDisplayFormat() throws {
        // Normalize from legacy, display, and lowercase
        XCTAssertEqual(try DIGIPIN.normalize("39J-49L-L8T4"), "39J49LL8T4")
        XCTAssertEqual(try DIGIPIN.normalize("39J 49LL 8T4"), "39J49LL8T4")
        XCTAssertEqual(try DIGIPIN.normalize("  39j49ll8t4\n"), "39J49LL8T4")
        XCTAssertEqual(try DIGIPIN.normalize("C4P8K63M4M", mode: .strict), "C4P8K63M4M")

        // Official May 2026 §2(c) 3-4-3 display format
        XCTAssertEqual(try DIGIPIN.formatForDisplay("C4P8K63M4M"), "C4P 8K63 M4M")
        XCTAssertEqual(try DIGIPIN.formatForDisplay("39j49ll8t4"), "39J 49LL 8T4")
        XCTAssertEqual(try DIGIPIN.formatForDisplay("39J-49L-L8T4", mode: .lenient), "39J 49LL 8T4")

        // Strict formatForDisplay rejects legacy hyphenated input
        XCTAssertThrowsError(try DIGIPIN.formatForDisplay("39J-49L-L8T4", mode: .strict)) { error in
            XCTAssertEqual(error as? DIGIPINError, .invalidDIGIPIN)
        }
    }

    // MARK: - Round-Trip & Precision Invariants

    func testRoundTripPrecisionAcrossIndia() throws {
        // Cell half-width at level 10: (36.0 / 4^10) / 2 ≈ 0.0000171661376953125°
        let maxHalfCellError = (36.0 / pow(4.0, 10.0)) / 2.0 + 1e-12

        let testPoints: [Coordinate] = [
            Coordinate(latitude: 8.0883, longitude: 77.5385),   // Kanyakumari
            Coordinate(latitude: 34.1526, longitude: 77.5771),  // Leh, Ladakh
            Coordinate(latitude: 23.0225, longitude: 72.5714),  // Ahmedabad
            Coordinate(latitude: 26.1445, longitude: 91.7362),  // Guwahati
            Coordinate(latitude: 11.6234, longitude: 92.7265),  // Port Blair (Andaman)
            Coordinate(latitude: 10.5667, longitude: 72.6417),  // Kavaratti (Lakshadweep)
            Coordinate(latitude: 22.5726, longitude: 88.3639),  // Kolkata
            Coordinate(latitude: 17.3850, longitude: 78.4867),  // Hyderabad
        ]

        for original in testPoints {
            let pin = try sut.generateDIGIPIN(for: original)
            let decoded = try sut.coordinate(from: pin)
            XCTAssertLessThanOrEqual(abs(decoded.latitude - original.latitude), maxHalfCellError)
            XCTAssertLessThanOrEqual(abs(decoded.longitude - original.longitude), maxHalfCellError)

            // Re-encoding the decoded center must yield the exact same DIGIPIN
            let reencoded = try sut.generateDIGIPIN(for: decoded)
            XCTAssertEqual(reencoded, pin)
        }
    }

    // MARK: - Distance Calculation

    func testDistanceBetweenCoordinates() {
        let bangalore = Coordinate(latitude: 12.9716, longitude: 77.5946)
        let newDelhi = Coordinate(latitude: 28.6139, longitude: 77.2090)

        XCTAssertEqual(DIGIPIN.distance(from: bangalore, to: bangalore), 0.0, accuracy: 1e-9)
        XCTAssertEqual(DIGIPIN.distance(from: bangalore, to: newDelhi), 1740, accuracy: 2.0)

        // Antipodal points should not produce NaN
        let antipodal = DIGIPIN.distance(
            from: Coordinate(latitude: 0.0, longitude: 0.0),
            to: Coordinate(latitude: 0.0, longitude: 180.0)
        )
        XCTAssertFalse(antipodal.isNaN)
        XCTAssertGreaterThan(antipodal, 20000.0)
    }

    func testDistanceBetweenDIGIPINs() throws {
        let pin1 = "4P3JK852C9" // Bangalore
        let pin2 = "39J49LL8T4" // New Delhi (Dak Bhawan)

        XCTAssertEqual(try sut.distance(from: pin1, to: pin1), 0.0, accuracy: 1e-9)
        XCTAssertEqual(try sut.distance(from: pin1, to: pin2), 1740, accuracy: 2.0)

        // Lenient mode supports legacy hyphenated codes
        XCTAssertEqual(
            try sut.distance(from: "4P3-JK8-52C9", to: "39J-49L-L8T4", mode: .lenient),
            1740,
            accuracy: 2.0
        )

        // Strict mode rejects legacy hyphenated codes
        XCTAssertThrowsError(try sut.distance(from: "4P3-JK8-52C9", to: "39J49LL8T4")) { error in
            XCTAssertEqual(error as? DIGIPINError, .invalidDIGIPIN)
        }
    }

    // MARK: - Bulk Operations

    func testBulkEncode() {
        let coordinates = [
            Coordinate(latitude: 12.9716, longitude: 77.5946),
            Coordinate(latitude: 28.622788, longitude: 77.213033),
            Coordinate(latitude: 40.0, longitude: 78.0),
        ]
        let results = sut.bulkEncode(coordinates)
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0], .success("4P3JK852C9"))
        XCTAssertEqual(results[1], .success("39J49LL8T4"))
        XCTAssertEqual(results[2], .failure(.outOfBounds))
    }

    func testBulkDecodeStrictAndLenient() {
        let codes = [
            "4P3JK852C9",   // canonical
            "39J-49L-L8T4", // legacy hyphenated
            "INVALID",      // invalid
        ]

        let strictResults = sut.bulkDecode(codes)
        XCTAssertEqual(strictResults.count, 3)
        if case .success(let coord1) = strictResults[0] {
            XCTAssertEqual(coord1.latitude, 12.971601, accuracy: 0.00001)
        } else {
            XCTFail("Canonical code should succeed in strict mode")
        }
        XCTAssertEqual(strictResults[1], .failure(.invalidDIGIPIN))
        XCTAssertEqual(strictResults[2], .failure(.invalidDIGIPIN))

        let lenientResults = sut.bulkDecode(codes, mode: .lenient)
        XCTAssertEqual(lenientResults.count, 3)
        if case .success(let coord2) = lenientResults[1] {
            XCTAssertEqual(coord2.latitude, 28.622793, accuracy: 0.00001)
        } else {
            XCTFail("Legacy code should succeed in lenient mode")
        }
        XCTAssertEqual(lenientResults[2], .failure(.invalidDIGIPIN))
    }

    // MARK: - Swift Concurrency, Codable & LocalizedError

    func testDIGIPINCanBeStoredInSendableType() throws {
        struct LocationService: Sendable {
            let maxDistanceKm: Double
            let digipin = DIGIPIN()

            func code(for coordinate: Coordinate) throws -> String {
                try digipin.generateDIGIPIN(for: coordinate)
            }
        }

        let service = LocationService(maxDistanceKm: 5)
        let coordinate = Coordinate(latitude: 28.622788, longitude: 77.213033)

        XCTAssertEqual(service.maxDistanceKm, 5)
        XCTAssertEqual(try service.code(for: coordinate), "39J49LL8T4")
    }

    func testCoordinateHashableAndCodable() throws {
        let coord = Coordinate(latitude: 28.622788, longitude: 77.213033)
        let data = try JSONEncoder().encode(coord)
        let decoded = try JSONDecoder().decode(Coordinate.self, from: data)
        XCTAssertEqual(decoded, coord)

        let set: Set<Coordinate> = [coord, decoded]
        XCTAssertEqual(set.count, 1)
    }

    func testLocalizedErrorDescriptions() {
        XCTAssertNotNil(DIGIPINError.outOfBounds.errorDescription)
        XCTAssertNotNil(DIGIPINError.invalidDIGIPIN.errorDescription)
        XCTAssertNotNil(DIGIPINError.gridCalculationError.errorDescription)
    }
}
