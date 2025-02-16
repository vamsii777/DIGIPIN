import Foundation

public enum DIGIPINError: Error {
    case outOfBounds
    case invalidDIGIPIN
    case gridCalculationError
}

public struct Coordinate: Equatable {
    public let latitude: Double
    public let longitude: Double
    
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct DIGIPIN {
    // MARK: - Private Constants
    private let L1: [[String]] = [
        ["0", "2", "0", "0"],
        ["3", "4", "5", "6"],
        ["G", "8", "7", "M"],
        ["J", "9", "K", "L"]
    ]
    
    private let L2: [[String]] = [
        ["J", "G", "9", "8"],
        ["K", "3", "2", "7"],
        ["L", "4", "5", "6"],
        ["M", "P", "W", "X"]
    ]
    
    private let bounds = (
        latitude: (min: 1.5, max: 39.0),
        longitude: (min: 63.5, max: 99.0)
    )
    
    private let divisions = 4
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// Generates a DIGIPIN code for the given coordinates
    /// - Parameters:
    ///   - coordinate: The coordinate for which to generate the DIGIPIN
    /// - Returns: A DIGIPIN string
    /// - Throws: DIGIPINError if coordinates are invalid or out of bounds
    public func generateDIGIPIN(for coordinate: Coordinate) throws -> String {
        try generateDIGIPIN(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    /// Generates a DIGIPIN code for the given latitude and longitude
    /// - Parameters:
    ///   - latitude: The latitude coordinate
    ///   - longitude: The longitude coordinate
    /// - Returns: A DIGIPIN string
    /// - Throws: DIGIPINError if coordinates are invalid or out of bounds
    public func generateDIGIPIN(latitude: Double, longitude: Double) throws -> String {
        guard isValidCoordinate(latitude: latitude, longitude: longitude) else {
            throw DIGIPINError.outOfBounds
        }
        
        var currentBounds = (
            latitude: (min: bounds.latitude.min, max: bounds.latitude.max),
            longitude: (min: bounds.longitude.min, max: bounds.longitude.max)
        )
        
        var digiPin = ""
        
        for level in 1...10 {
            let (r, c) = try findGridCell(
                latitude: latitude,
                longitude: longitude,
                in: currentBounds
            )
            
            if level == 1 {
                let ch = L1[r][c]
                digiPin.append(ch)
            } else {
                digiPin.append(L2[r][c])
                if level == 3 || level == 6 { digiPin.append("-") }
            }
            
            currentBounds = updateBounds(row: r, column: c, currentBounds: currentBounds)
        }
        
        return digiPin
    }
    
    /// Converts a DIGIPIN code back to geographic coordinates
    /// - Parameter digiPin: The DIGIPIN code to convert
    /// - Returns: The corresponding geographic coordinate
    /// - Throws: DIGIPINError if the DIGIPIN code is invalid
    public func coordinate(from digiPin: String) throws -> Coordinate {
        let cleanPin = digiPin.replacingOccurrences(of: "-", with: "")
        guard cleanPin.count == 10 else { throw DIGIPINError.invalidDIGIPIN }
        
        var currentBounds = (
            latitude: (min: bounds.latitude.min, max: bounds.latitude.max),
            longitude: (min: bounds.longitude.min, max: bounds.longitude.max)
        )
        
        for level in 0..<10 {
            let index = cleanPin.index(cleanPin.startIndex, offsetBy: level)
            let ch = String(cleanPin[index])
            
            let (r, c) = try findGridCell(for: ch, level: level)
            currentBounds = updateBounds(row: r, column: c, currentBounds: currentBounds)
        }
        
        return Coordinate(
            latitude: (currentBounds.latitude.min + currentBounds.latitude.max) / 2.0,
            longitude: (currentBounds.longitude.min + currentBounds.longitude.max) / 2.0
        )
    }
    
    // MARK: - Private Methods
    
    private func isValidCoordinate(latitude: Double, longitude: Double) -> Bool {
        latitude >= bounds.latitude.min && 
        latitude <= bounds.latitude.max && 
        longitude >= bounds.longitude.min && 
        longitude <= bounds.longitude.max
    }
    
    private func findGridCell(
        latitude: Double,
        longitude: Double,
        in currentBounds: (latitude: (min: Double, max: Double), longitude: (min: Double, max: Double))
    ) throws -> (row: Int, column: Int) {
        let latDiv = (currentBounds.latitude.max - currentBounds.latitude.min) / Double(divisions)
        let lonDiv = (currentBounds.longitude.max - currentBounds.longitude.min) / Double(divisions)
        
        // Handle the maximum value edge case
        if latitude == currentBounds.latitude.max {
            if let r = (0..<divisions).first(where: { index in
                let upper = currentBounds.latitude.max - (Double(index) * latDiv)
                let lower = upper - latDiv
                return latitude >= lower
            }) {
                guard let c = findLongitudeCell(longitude: longitude, lonDiv: lonDiv, currentBounds: currentBounds) else {
                    throw DIGIPINError.gridCalculationError
                }
                return (r, c)
            }
        }
        
        if longitude == currentBounds.longitude.max {
            if let c = (0..<divisions).last {
                guard let r = findLatitudeCell(latitude: latitude, latDiv: latDiv, currentBounds: currentBounds) else {
                    throw DIGIPINError.gridCalculationError
                }
                return (r, c)
            }
        }
        
        // Normal case
        guard let r = findLatitudeCell(latitude: latitude, latDiv: latDiv, currentBounds: currentBounds),
              let c = findLongitudeCell(longitude: longitude, lonDiv: lonDiv, currentBounds: currentBounds) else {
            throw DIGIPINError.gridCalculationError
        }
        
        return (r, c)
    }
    
    private func findLatitudeCell(latitude: Double, latDiv: Double, currentBounds: (latitude: (min: Double, max: Double), longitude: (min: Double, max: Double))) -> Int? {
        return (0..<divisions).first(where: { index in
            let upper = currentBounds.latitude.max - (Double(index) * latDiv)
            let lower = upper - latDiv
            return latitude >= lower && latitude <= upper
        })
    }
    
    private func findLongitudeCell(longitude: Double, lonDiv: Double, currentBounds: (latitude: (min: Double, max: Double), longitude: (min: Double, max: Double))) -> Int? {
        return (0..<divisions).first(where: { index in
            let lower = currentBounds.longitude.min + (Double(index) * lonDiv)
            let upper = lower + lonDiv
            return longitude >= lower && longitude <= upper
        })
    }
    
    private func findGridCell(for character: String, level: Int) throws -> (row: Int, column: Int) {
        let grid = level == 0 ? L1 : L2
        
        for row in 0..<divisions {
            for col in 0..<divisions {
                if grid[row][col] == character {
                    return (row, col)
                }
            }
        }
        
        throw DIGIPINError.invalidDIGIPIN
    }
    
    private func updateBounds(
        row: Int,
        column: Int,
        currentBounds: (latitude: (min: Double, max: Double), longitude: (min: Double, max: Double))
    ) -> (latitude: (min: Double, max: Double), longitude: (min: Double, max: Double)) {
        let latDiv = (currentBounds.latitude.max - currentBounds.latitude.min) / Double(divisions)
        let lonDiv = (currentBounds.longitude.max - currentBounds.longitude.min) / Double(divisions)
        
        return (
            latitude: (
                min: currentBounds.latitude.max - (latDiv * Double(row + 1)),
                max: currentBounds.latitude.max - (latDiv * Double(row))
            ),
            longitude: (
                min: currentBounds.longitude.min + (lonDiv * Double(column)),
                max: currentBounds.longitude.min + (lonDiv * Double(column + 1))
            )
        )
    }
}
