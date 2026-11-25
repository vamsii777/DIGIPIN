# DIGIPIN Developer Guide

## Introduction

DIGIPIN (Digital Postal Index Number) is India Post's standardized, geo-coded addressing grid. This guide covers integrating the Swift `DIGIPIN` library and CLI in full compliance with the **India Post DIGIPIN Technical Specification & Architecture Standard — Version 2.0.0 (May 2026 Standards Revision)**.

## Key Concepts

- **Uniform 4×4 Grid**: DIGIPIN subdivides India's territory across 10 hierarchical levels using the same 4×4 symbol matrix:

```
[
  ["F", "C", "9", "8"],
  ["J", "3", "2", "7"],
  ["K", "4", "5", "6"],
  ["L", "M", "P", "T"]
]
```

- **Bounds (EPSG:4326)**: Latitude `2.5°N` to `38.5°N` and Longitude `63.5°E` to `99.5°E`.
- **Canonical Format (§2b, §2c)**: Continuous 10-character uppercase string (`39J49LL8T4`). Hyphens (`-`) and special characters are prohibited.
- **Optional Display Format (§2c)**: `3-4-3` space grouping (`39J 49LL 8T4`) for UI display only — always store and exchange the continuous 10-character string.
- **Grid-Line Tie-Breaking (§4.4)**: Coordinates on vertical grid lines map eastward; horizontal grid lines map northward; intersections map northeast; top (`38.5°N`) and right (`99.5°E`) boundaries clamp southward and westward respectively.

## Usage

### Encoding & Display Formatting

```swift
let digipin = DIGIPIN()
let coordinate = Coordinate(latitude: 28.622788, longitude: 77.213033)
let canonical = try digipin.generateDIGIPIN(for: coordinate) // "39J49LL8T4"
let display = try DIGIPIN.formatForDisplay(canonical)        // "39J 49LL 8T4"
```

### Decoding & Validation

```swift
let digipin = DIGIPIN()

// Strict May 2026 v2.0.0 validation (default; trims whitespace & normalizes case)
let coordinate = try digipin.coordinate(from: "39j49ll8t4")

// Validate before decoding
if DIGIPIN.isValid("39J49LL8T4") {
    // Guaranteed canonical 10-character DIGIPIN
}
```

### Migrating from Legacy `v2.x` (`XXX-XXX-XXXX`) Codes

If your database or upstream clients still use March 2025 hyphenated codes (`39J-49L-L8T4`), use `DIGIPIN.normalize(_:mode:)` to migrate stored records and `.lenient` during your transition window:

```swift
// Normalize legacy 3-3-4 hyphenated or 3-4-3 display codes to canonical 10-char format
let canonical = try DIGIPIN.normalize("39J-49L-L8T4") // "39J49LL8T4"

// Decode legacy codes explicitly during migration
let coordinate = try digipin.coordinate(from: "39J-49L-L8T4", mode: .lenient)
```

## Command-Line Interface (CLI)

```bash
# Encode to canonical 10-character DIGIPIN (add --display for 3-4-3 spaced display)
$ digipin encode 12.9716 77.5946
4P3JK852C9

$ digipin encode --display 12.9716 77.5946
4P3 JK85 2C9

# Decode (add --lenient to accept legacy 3-3-4 hyphenated or 3-4-3 spaced inputs)
$ digipin decode 4P3JK852C9
12.971601, 77.594584

# Normalize legacy/display code to canonical 10-character format
$ digipin normalize 39J-49L-L8T4
39J49LL8T4

# Compute great-circle distance (in km)
$ digipin distance 4P3JK852C9 39J49LL8T4
1740.12 km
```

## Best Practices

- Always persist and transmit the **continuous 10-character uppercase** DIGIPIN in databases and APIs.
- Use `DIGIPIN.formatForDisplay(_:)` only at the UI presentation layer.
- Use `DIGIPIN.normalize(_:)` to migrate existing hyphenated records in batch jobs.
- Handle errors using `DIGIPINError` (which conforms to `LocalizedError`).

## References
- [Official India Post DIGIPIN Repository (`INDIAPOST-gov/digipin`)](https://github.com/INDIAPOST-gov/digipin)
- [DIGIPIN Technical Specification & Architecture Standard (May 2026 v2.0.0)](https://github.com/INDIAPOST-gov/digipin/blob/main/docs/DIGIPIN_Technical_Document.md)
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Swift ArgumentParser Documentation](https://github.com/apple/swift-argument-parser)
