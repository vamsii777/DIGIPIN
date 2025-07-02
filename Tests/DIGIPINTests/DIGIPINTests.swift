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
    
    // MARK: - DIGIPIN Generation Tests
    
    func testValidDIGIPINGeneration() throws {
        let coordinate = Coordinate(latitude: 12.9716, longitude: 77.5946)
        let digipin = try sut.generateDIGIPIN(for: coordinate)
        // The expected code is based on the new compliant implementation
        XCTAssertEqual(digipin, "4P3-JK8-52C9")
        XCTAssertEqual(digipin.count, 12) // Including hyphens
        XCTAssertFalse(digipin.contains("0"))
        let digipinAlt = try sut.generateDIGIPIN(latitude: coordinate.latitude, longitude: coordinate.longitude)
        XCTAssertEqual(digipin, digipinAlt)
    }
    
    func testOutOfBoundsLatitude() {
        let coordinate = Coordinate(latitude: 40.0, longitude: 78.12351)
        XCTAssertThrowsError(try sut.generateDIGIPIN(for: coordinate)) { error in
            XCTAssertEqual(error as? DIGIPINError, .outOfBounds)
        }
    }
    
    func testOutOfBoundsLongitude() {
        let coordinate = Coordinate(latitude: 17.59551, longitude: 120.0)
        XCTAssertThrowsError(try sut.generateDIGIPIN(for: coordinate)) { error in
            XCTAssertEqual(error as? DIGIPINError, .outOfBounds)
        }
    }
    
    // MARK: - Coordinate Lookup Tests
    
    func testReverseLookup() throws {
        let originalCoordinate = Coordinate(latitude: 28.6139, longitude: 77.2090)
        let digipin = try sut.generateDIGIPIN(for: originalCoordinate)
        let decodedCoordinate = try sut.coordinate(from: digipin)
        XCTAssertLessThan(abs(decodedCoordinate.latitude - originalCoordinate.latitude), 0.005)
        XCTAssertLessThan(abs(decodedCoordinate.longitude - originalCoordinate.longitude), 0.005)
    }
    
    func testInvalidDIGIPIN() {
        let invalidDigipin = "XXXX-XXXX-XX"
        XCTAssertThrowsError(try sut.coordinate(from: invalidDigipin)) { error in
            XCTAssertEqual(error as? DIGIPINError, .invalidDIGIPIN)
        }
    }
    
    // MARK: - Edge Cases
    
    func testMinimumBoundaries() throws {
        let coordinate = Coordinate(latitude: 2.5, longitude: 63.5)
        let digipin = try sut.generateDIGIPIN(for: coordinate)
        XCTAssertFalse(digipin.isEmpty)
        XCTAssertEqual(digipin.count, 12)
    }
    
    func testMaximumBoundaries() throws {
        let coordinate = Coordinate(latitude: 38.5, longitude: 99.5)
        let digipin = try sut.generateDIGIPIN(for: coordinate)
        XCTAssertFalse(digipin.isEmpty)
        XCTAssertEqual(digipin.count, 12)
        let aboveMaxCoordinate = Coordinate(latitude: 38.51, longitude: 99.51)
        XCTAssertThrowsError(try sut.generateDIGIPIN(for: aboveMaxCoordinate)) { error in
            XCTAssertEqual(error as? DIGIPINError, .outOfBounds)
        }
    }
    
    func testDIGIPINFormat() throws {
        let coordinate = Coordinate(latitude: 28.6139, longitude: 77.2090)
        let digipin = try sut.generateDIGIPIN(for: coordinate)
        let components = digipin.split(separator: "-")
        XCTAssertEqual(components.count, 3)
        XCTAssertEqual(components[0].count, 3)
        XCTAssertEqual(components[1].count, 3)
        XCTAssertEqual(components[2].count, 4)
    }
    
    func testInvalidDIGIPINFormats() {
        let invalidFormats = [
            "",                    // Empty string
            "ABC",                 // Too short
            "ABC-DEF-GHIJK",      // Too long
            "123-456-789",        // All numbers
            "AAA-BBB-CCCC"        // All letters
        ]
        for invalidFormat in invalidFormats {
            XCTAssertThrowsError(try sut.coordinate(from: invalidFormat)) { error in
                XCTAssertTrue(error is DIGIPINError)
            }
        }
    }
    
    func testOfficialDakBhawanDIGIPIN() throws {
        // Official example from India Post documentation
        let coordinate = Coordinate(latitude: 28.622788, longitude: 77.213033)
        let digipin = try sut.generateDIGIPIN(for: coordinate)
        // The expected code is as per the official doc: 39J-49L-L8T4
        XCTAssertEqual(digipin, "39J-49L-L8T4")
        let decoded = try sut.coordinate(from: digipin)
        XCTAssertLessThan(abs(decoded.latitude - coordinate.latitude), 0.005)
        XCTAssertLessThan(abs(decoded.longitude - coordinate.longitude), 0.005)
    }
    
    func testDistanceBetweenCoordinates() {
        let coord1 = Coordinate(latitude: 12.9716, longitude: 77.5946) // Bangalore
        let coord2 = Coordinate(latitude: 28.6139, longitude: 77.2090) // New Delhi
        let distance = DIGIPIN.distance(from: coord1, to: coord2)
        // Known value: ~1740 km (allowing for small floating point error)
        XCTAssertEqual(distance, 1740, accuracy: 2.0)
    }

    func testDistanceBetweenDIGIPINs() throws {
        let pin1 = "4P3-JK8-52C9" // Bangalore
        let pin2 = "39J-49L-L8T4" // New Delhi (Dak Bhawan)
        let distance = try sut.distance(from: pin1, to: pin2)
        // Known value: ~1740 km (allowing for small floating point error)
        XCTAssertEqual(distance, 1740, accuracy: 2.0)
    }

    func testDistanceInvalidDIGIPIN() {
        XCTAssertThrowsError(try sut.distance(from: "INVALID", to: "39J-49L-L8T4")) { error in
            XCTAssertTrue(error is DIGIPINError)
        }
    }

    func testBulkEncode() {
        let coordinates = [
            Coordinate(latitude: 12.9716, longitude: 77.5946), // valid
            Coordinate(latitude: 28.6139, longitude: 77.2090), // valid
            Coordinate(latitude: 40.0, longitude: 78.0)         // invalid (out of bounds)
        ]
        let results = sut.bulkEncode(coordinates)
        XCTAssertEqual(results.count, 3)
        if case .success(let code1) = results[0] {
            XCTAssertEqual(code1, "4P3-JK8-52C9")
        } else {
            XCTFail("First coordinate should encode successfully")
        }
        if case .success = results[1] {
            // Accept any valid code
        } else {
            XCTFail("Second coordinate should encode successfully")
        }
        if case .failure(let error) = results[2] {
            XCTAssertEqual(error, .outOfBounds)
        } else {
            XCTFail("Third coordinate should fail with outOfBounds")
        }
    }

    func testBulkDecode() {
        let codes = [
            "4P3-JK8-52C9", // valid
            "39J-49L-L8T4", // valid
            "XXXX-XXXX-XX"  // invalid
        ]
        let results = sut.bulkDecode(codes)
        XCTAssertEqual(results.count, 3)
        if case .success(let coord1) = results[0] {
            XCTAssertEqual(round(coord1.latitude * 10000) / 10000, 12.9716, accuracy: 0.01)
        } else {
            XCTFail("First code should decode successfully")
        }
        if case .success(let coord2) = results[1] {
            XCTAssertEqual(round(coord2.latitude * 10000) / 10000, 28.6228, accuracy: 0.01)
        } else {
            XCTFail("Second code should decode successfully")
        }
        if case .failure(let error) = results[2] {
            XCTAssertEqual(error, .invalidDIGIPIN)
        } else {
            XCTFail("Third code should fail with invalidDIGIPIN")
        }
    }
}
