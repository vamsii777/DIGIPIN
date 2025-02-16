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
        let coordinate = Coordinate(latitude: 17.23078, longitude: 78.43202)
        let digipin = try sut.generateDIGIPIN(for: coordinate)
        
        XCTAssertEqual(digipin, "822-852-XG7M")
        XCTAssertEqual(digipin.count, 12) // Including hyphens
        XCTAssertFalse(digipin.contains("0"))
        
        let digipinAlt = try sut.generateDIGIPIN(latitude: coordinate.latitude, longitude: coordinate.longitude)
        XCTAssertEqual(digipin, digipinAlt)
    }
    
    func testOutOfBoundsLatitude() {
        let coordinate = Coordinate(latitude: 50.0, longitude: 78.12351)
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
        let originalCoordinate = Coordinate(latitude: 17.59551, longitude: 78.12351)
        let digipin = try sut.generateDIGIPIN(for: originalCoordinate)
        let decodedCoordinate = try sut.coordinate(from: digipin)
        
        XCTAssertLessThan(abs(decodedCoordinate.latitude - originalCoordinate.latitude), 0.0001)
        XCTAssertLessThan(abs(decodedCoordinate.longitude - originalCoordinate.longitude), 0.0001)
    }
    
    func testInvalidDIGIPIN() {
        let invalidDigipin = "XXXX-XXXX-XX"
        XCTAssertThrowsError(try sut.coordinate(from: invalidDigipin)) { error in
            XCTAssertEqual(error as? DIGIPINError, .invalidDIGIPIN)
        }
    }
    
    // MARK: - Edge Cases
    
    func testMinimumBoundaries() throws {
        let coordinate = Coordinate(latitude: 1.5, longitude: 63.5)
        let digipin = try sut.generateDIGIPIN(for: coordinate)
        
        XCTAssertFalse(digipin.isEmpty)
        XCTAssertEqual(digipin.count, 12)
    }
    
    func testMaximumBoundaries() throws {
        let coordinate = Coordinate(latitude: 39.0, longitude: 99.0)
        let digipin = try sut.generateDIGIPIN(for: coordinate)
        
        XCTAssertFalse(digipin.isEmpty)
        XCTAssertEqual(digipin.count, 12)
        
        let aboveMaxCoordinate = Coordinate(latitude: 39.1, longitude: 99.1)
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
}
