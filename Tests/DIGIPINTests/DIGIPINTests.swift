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
}
