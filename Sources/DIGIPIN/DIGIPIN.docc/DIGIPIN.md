# ``DIGIPIN``

> **Note:** This library is **100% compliant** with the official **India Post DIGIPIN Technical Specification & Architecture Standard — Version 2.0.0 (May 2026 Standards Revision)**.

A Swift library and CLI for generating, decoding, validating, and normalizing India Post's DIGIPIN codes.

## Overview

DIGIPIN (Digital Postal Index Number) is India Post's national-level geo-coded addressing grid developed in collaboration with IIT Hyderabad and NRSC, ISRO. It encodes geographic coordinates (EPSG:4326 / WGS84) within India's bounding box into a canonical **continuous 10-character uppercase alphanumeric code** (e.g., `39J49LL8T4`) representing an approximately `3.8m × 3.8m` grid cell.

Per the **May 2026 Standards Revision (v2.0.0)**:
- **System / Storage / API Representation**: Continuous 10-character uppercase string (`39J49LL8T4`). Hyphens (`-`) and other punctuation are **not permitted**.
- **Optional Display Representation**: `3-4-3` space grouping (`39J 49LL 8T4`) for human-readable UI display only.

## Features

- Generate canonical 10-character DIGIPIN codes from geographic coordinates
- Decode DIGIPIN codes back to their central latitude and longitude (case-insensitive, trims leading/trailing whitespace)
- Strict May 2026 v2.0.0 validation by default, with explicit `.lenient` mode and `DIGIPIN.normalize(_:mode:)` for migrating legacy `3-3-4` hyphenated and `3-4-3` display codes
- Official `3-4-3` space-grouped display formatting via `DIGIPIN.formatForDisplay(_:mode:)`
- Bulk encode/decode and great-circle distance calculation
- Full Swift 6 `Sendable` concurrency compliance

## Topics

### Essentials

- ``DIGIPIN/generateDIGIPIN(for:)``
- ``DIGIPIN/generateDIGIPIN(latitude:longitude:)``
- ``DIGIPIN/coordinate(from:mode:)``
- ``Coordinate``

### Validation, Migration & Display

- ``DIGIPINValidationMode``
- ``DIGIPIN/isValid(_:mode:)``
- ``DIGIPIN/normalize(_:mode:)``
- ``DIGIPIN/formatForDisplay(_:mode:)``

### Distance & Bulk Operations

- ``DIGIPIN/distance(from:to:)``
- ``DIGIPIN/distance(from:to:mode:)``
- ``DIGIPIN/bulkEncode(_:)``
- ``DIGIPIN/bulkDecode(_:mode:)``

### Error Handling

- ``DIGIPINError``

## Usage

### Generating a DIGIPIN Code

```swift
let digipin = DIGIPIN()
let coordinate = Coordinate(latitude: 28.622788, longitude: 77.213033)

do {
    let code = try digipin.generateDIGIPIN(for: coordinate)
    print(code) // "39J49LL8T4"

    let display = try DIGIPIN.formatForDisplay(code)
    print(display) // "39J 49LL 8T4"
} catch {
    print("Error generating DIGIPIN: \(error)")
}
```

### Converting DIGIPIN to Coordinates

```swift
let digipin = DIGIPIN()

do {
    // Strict May 2026 v2.0.0 validation (default)
    let coordinate = try digipin.coordinate(from: "39J49LL8T4")
    print("Latitude: \(coordinate.latitude), Longitude: \(coordinate.longitude)")

    // Optional lenient decoding for migrating legacy 3-3-4 hyphenated or 3-4-3 spaced inputs
    let legacyCoord = try digipin.coordinate(from: "39J-49L-L8T4", mode: .lenient)
    print("Legacy decoded: \(legacyCoord)")
} catch {
    print("Error converting DIGIPIN: \(error)")
}
```

## Geographic Coverage

The DIGIPIN system covers the following EPSG:4326 geographic bounds:
- Latitude: `2.5°N` to `38.5°N`
- Longitude: `63.5°E` to `99.5°E`

This range encompasses mainland India, Andaman and Nicobar Islands, Lakshadweep Islands, and India's maritime Exclusive Economic Zone (EEZ).

## Implementation Details

The DIGIPIN system uses a hierarchical grid system with a uniform 4×4 grid across all 10 levels:

```
[
  ["F", "C", "9", "8"],
  ["J", "3", "2", "7"],
  ["K", "4", "5", "6"],
  ["L", "M", "P", "T"]
]
```

At each level, the bounding box is subdivided into 4×4 cells, using reversed row indexing (`row = 3 - floor((lat - minLat) / latDiv)`) to match the official grid orientation and §4.4 grid-line tie-breaking rules.

For full specification details, see:
- [Official India Post DIGIPIN Repository (`INDIAPOST-gov/digipin`)](https://github.com/INDIAPOST-gov/digipin)
- [DIGIPIN Technical Specification & Architecture Standard (May 2026 v2.0.0)](https://github.com/INDIAPOST-gov/digipin/blob/main/docs/DIGIPIN_Technical_Document.md)

## Command-Line Interface (CLI)

The DIGIPIN package includes a CLI tool (`digipin`) for encoding, decoding, normalizing, and computing distances between DIGIPIN codes.

### Usage

```bash
# Encode latitude and longitude to a canonical 10-character DIGIPIN code
$ digipin encode <latitude> <longitude> [--display]

# Decode a DIGIPIN code to latitude and longitude
$ digipin decode <DIGIPIN> [--lenient]

# Normalize a legacy or display DIGIPIN to canonical 10-character format
$ digipin normalize <DIGIPIN> [--display]

# Compute the distance (in km) between two DIGIPIN codes
$ digipin distance <DIGIPIN1> <DIGIPIN2> [--lenient]
```

### Examples

```bash
$ digipin encode 12.9716 77.5946
4P3JK852C9

$ digipin encode --display 12.9716 77.5946
4P3 JK85 2C9

$ digipin decode 4P3JK852C9
12.971601, 77.594584

$ digipin normalize 39J-49L-L8T4
39J49LL8T4

$ digipin distance 4P3JK852C9 39J49LL8T4
1740.12 km
```

## Changelog

### Version 3.0.0 (2026-11-25)
- Breaking Change
    - **100% compliant with the India Post DIGIPIN Technical Specification & Architecture Standard — Version 2.0.0 (May 2026 Standards Revision)** ([INDIAPOST-gov/digipin](https://github.com/INDIAPOST-gov/digipin)).
    - `generateDIGIPIN` now emits the canonical **continuous 10-character uppercase string** (e.g., `39J49LL8T4`) without hyphens (§2b, §2c).
    - `coordinate(from:)`, `distance(from:to:)`, and `bulkDecode(_:)` now enforce **strict May 2026 validation** by default: leading/trailing whitespace is trimmed, ASCII letters are normalized to uppercase, and hyphens, interior spaces, and non-approved characters are rejected.
- Added
    - `DIGIPINValidationMode` (`.strict` default and `.lenient` opt-in for migrating legacy `3-3-4` hyphenated and official `3-4-3` spaced display codes).
    - `DIGIPIN.isValid(_:mode:)` validation helper.
    - `DIGIPIN.normalize(_:mode:)` helper for migrating legacy hyphenated or display-formatted DIGIPINs to canonical 10-character format.
    - `DIGIPIN.formatForDisplay(_:mode:)` helper for official May 2026 §2(c) `3-4-3` space-grouped display formatting (`39J 49LL 8T4`).
    - CLI flags `--display` (on `encode`/`normalize`), `--lenient` (on `decode`/`distance`), and new `normalize` subcommand.
    - `LocalizedError` conformance on `DIGIPINError`; `Hashable` and `Codable` conformances on `Coordinate`.
    - Exhaustive edge-case unit tests (§4.4 grid-line tie-breaking, corner boundaries, `NaN`/`±Infinity`, Unicode/fullwidth rejections, and 100% parity verification against official `INDIAPOST-gov/digipin/src/digipin.js`).
- Fixed
    - Fixed `DIGIPINCLITests` executable lookup (`digipin` instead of `digipin-cli`) so CLI integration tests run instead of skipping.
    - Added explicit `isFinite` coordinate validation and O(1) ASCII grid lookup.
    - Clamped Haversine radicand in `DIGIPIN.distance(from:to:)` to prevent `NaN` on antipodal coordinates.
    - Updated documentation links to `INDIAPOST-gov/digipin` and fixed duplicate README badge.
    ---

### Version 2.3.0 (2026-04-01)
- Added
    - Swift 6 `Sendable` conformance across `DIGIPIN`, `Coordinate`, and `DIGIPINError`.
    - CI matrix updates for Xcode 16 / Swift 6.
    ---

### Version 2.2.0 (2025-07-02)
- Added
    - Bulk encode (`bulkEncode`) and bulk decode (`bulkDecode`) API to the DIGIPIN library for efficient batch operations.
    - Unit tests for bulk encode and decode, covering valid, invalid, and mixed input cases.
- Changed
    - Improved error handling for batch operations in the DIGIPIN library.
    ---

### Version 2.1.0 (2025-07-01)
- Added
    - CLI tool (`digipin`) for encoding, decoding, and distance calculation.
    - Public distance calculation API to the DIGIPIN library.
    - CLI integration tests for encode, decode, and distance commands.
    - Swift 6 concurrency compliance for CLI and library.
- Changed
    - Improved documentation and usage examples for CLI and distance features.
    - Updated test targets and structure for CLI integration.
- Fixed
    - Fixed SwiftPM test discovery for CLI tests.
    - Fixed concurrency warnings in CLI code for Swift 6.
    ---

### Version 2.0.0 (2025-06-30)
- Breaking Change
    - The DIGIPIN implementation is now **fully compliant** with the official India Post specification (March 2025 v1.0.0).
    - Previous versions (including `1.0.0`) may generate incompatible codes. All users should upgrade to this version for official compatibility.
- Added
    - Official grid, bounds, and encoding/decoding logic as per India Post.
    - Updated documentation, usage examples, and developer guide.
    - Additional unit tests for official and edge-case examples.
- Changed
    - Refactored code for clarity, immutability, and best Swift practices.
    - Improved error messages and type safety.
- Fixed
    - Corrected grid, bounds, and logic to match the official DIGIPIN system.
    ---

### Version 1.0.0 (2025-02-17)
- Added
    - Initial release of the DIGIPIN Swift library.
    - Encode latitude/longitude to DIGIPIN and decode DIGIPIN to coordinates.
    - Input validation and error handling.
    - Documentation and usage examples.
    - Unit tests for basic functionality.
- Note
    - This version was **not fully compliant** with the official India Post DIGIPIN specification. Users should upgrade to `2.0.0` or later for official compatibility.
    ---
