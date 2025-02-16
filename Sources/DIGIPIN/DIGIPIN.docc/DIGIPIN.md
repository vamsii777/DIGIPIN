# ``DIGIPIN``

A Swift library for generating and handling India Post's DIGIPIN codes - a geographic coordinate encoding system.

## Overview

DIGIPIN (Digital Postal Index Number) is India Post's innovative solution for encoding geographic coordinates into easily readable and communicable codes. This library provides a Swift implementation for generating and decoding DIGIPIN codes.

A DIGIPIN code is a unique 10-character alphanumeric code (formatted as XXX-XXX-XXXX) that represents a specific geographic location within India's territory. The system divides the country's geographic area into a hierarchical grid system, providing precise location information.

## Features

- Generate DIGIPIN codes from geographic coordinates (latitude/longitude)
- Convert DIGIPIN codes back to geographic coordinates
- Validation of coordinates within India's territorial bounds
- Error handling for invalid inputs and out-of-bounds coordinates

## Topics

### Essentials

- ``DIGIPIN/generateDIGIPIN(for:)``
- ``DIGIPIN/coordinate(from:)``
- ``Coordinate``

### Error Handling

- ``DIGIPINError``

## Usage

### Generating a DIGIPIN Code

```swift
let digipin = DIGIPIN()
let coordinate = Coordinate(latitude: 28.6139, longitude: 77.2090)

do {
    let code = try digipin.generateDIGIPIN(for: coordinate)
    print(code) // Outputs a formatted DIGIPIN code
} catch {
    print("Error generating DIGIPIN: \(error)")
}
```

### Converting DIGIPIN to Coordinates

```swift
let digipin = DIGIPIN()

do {
    let coordinate = try digipin.coordinate(from: "ABC-DEF-GHIJ")
    print("Latitude: \(coordinate.latitude), Longitude: \(coordinate.longitude)")
} catch {
    print("Error converting DIGIPIN: \(error)")
}
```

## Geographic Coverage

The DIGIPIN system covers the following geographic bounds:
Latitude: 1.5°N to 39.0°N
Longitude: 63.5°E to 99.0°E

This range encompasses the entire territory of India and includes sufficient buffer zones.

## Implementation Details

The DIGIPIN system uses a hierarchical grid system with two lookup tables (L1 and L2) to generate unique codes. Each character in the DIGIPIN represents a specific grid cell at different levels of precision, allowing for accurate location encoding and decoding.
