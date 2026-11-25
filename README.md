<div align="center">
    <h1>DIGIPIN</h1>
    <a href="https://swift.org">
        <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fvamsii777%2FDIGIPIN%2Fbadge%3Ftype%3Dswift-versions" alt="Swift Versions">
    </a>
    <a href="https://swiftpackageindex.com/vamsii777/DIGIPIN">
        <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fvamsii777%2FDIGIPIN%2Fbadge%3Ftype%3Dplatforms" alt="Platforms">
    </a>
</div>
<div align="center" style="margin-top: 2px;">
    <a href="https://swiftpackageindex.com/vamsii777/DIGIPIN/documentation">
        <img src="https://img.shields.io/badge/read_the-docs-2ea44f?logo=readthedocs&logoColor=white" alt="Documentation">
    </a>
    <a href="LICENSE">
        <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License">
    </a>
    <a href="https://github.com/vamsii777/DIGIPIN/actions/workflows/tests.yml">
        <img src="https://img.shields.io/github/actions/workflow/status/vamsii777/DIGIPIN/tests.yml?event=push&style=flat&logo=github&label=tests" alt="Continuous Integration">
    </a>
</div>
<br>

🌍 📍 A Swift library & CLI for **India Post's DIGIPIN (Digital Postal Index Number)** system — **100% compliant with the India Post DIGIPIN Technical Specification & Architecture Standard v2.0.0 (May 2026 Standards Revision)**.

## 🗺️ Geographic Encoding

The `DIGIPIN` framework encodes any coordinate within India's official bounding box into a canonical **continuous 10-character uppercase alphanumeric DIGIPIN** (`39J49LL8T4`) representing an approximately `3.8m × 3.8m` grid cell, and decodes it back to its central latitude and longitude.

Add the `DIGIPIN` product to your target's dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "DIGIPIN", package: "digipin")
    ]
)
```

### Quick Example

```swift
import DIGIPIN

let digipin = DIGIPIN()

// Encode a coordinate into a canonical 10-character DIGIPIN (May 2026 v2.0.0 standard)
let coordinate = Coordinate(latitude: 28.622788, longitude: 77.213033) // Dak Bhawan (official example)
let code = try digipin.generateDIGIPIN(for: coordinate)
print(code) // "39J49LL8T4"

// Format for human-readable UI display using the official 3-4-3 space grouping
let displayCode = try DIGIPIN.formatForDisplay(code)
print(displayCode) // "39J 49LL 8T4"

// Decode a canonical DIGIPIN back to its central coordinate (case-insensitive, trims whitespace)
let location = try digipin.coordinate(from: "39J49LL8T4")
print("Lat: \(location.latitude), Long: \(location.longitude)")
```

## 🔄 Migrating from v2.x (March 2025 Format) to v3.0.0 (May 2026 Standard)

In **May 2026 (DIGIPIN Standard v2.0.0)**, India Post prohibited hyphens (`-`) in DIGIPIN codes and standardized on:
- **Canonical / Storage / API format**: Continuous 10-character uppercase string (`39J49LL8T4`) — no hyphens or spaces.
- **Optional Display format**: `3-4-3` space grouping (`39J 49LL 8T4`) for UI presentation only.

If your application has existing stored `3-3-4` hyphenated codes (e.g., `"39J-49L-L8T4"`) or receives space-formatted display input from users:

```swift
// 1. Migrate stored legacy or display codes to canonical 10-character format
let canonical = try DIGIPIN.normalize("39J-49L-L8T4") // "39J49LL8T4"

// 2. Opt in to lenient decoding during a transitional period
let coord = try digipin.coordinate(from: "39J-49L-L8T4", mode: .lenient)
let dist  = try digipin.distance(from: "4P3-JK8-52C9", to: "39J-49L-L8T4", mode: .lenient)
let batch = digipin.bulkDecode(["4P3JK852C9", "39J-49L-L8T4"], mode: .lenient)

// 3. Validate codes strictly (default) or leniently
DIGIPIN.isValid("39J49LL8T4")                    // true
DIGIPIN.isValid("39J-49L-L8T4")                  // false (strict May 2026 standard)
DIGIPIN.isValid("39J-49L-L8T4", mode: .lenient)  // true
```

## 🖥️ Command-Line Interface (CLI)

```bash
# Encode latitude and longitude to a canonical 10-character DIGIPIN
digipin encode 12.9716 77.5946
# -> 4P3JK852C9

# Encode using the official May 2026 3-4-3 spaced display format
digipin encode --display 12.9716 77.5946
# -> 4P3 JK85 2C9

# Decode a canonical DIGIPIN (use --lenient for legacy hyphenated or display spaced codes)
digipin decode 4P3JK852C9
# -> 12.971601, 77.594584

# Normalize a legacy or display DIGIPIN to canonical format
digipin normalize 39J-49L-L8T4
# -> 39J49LL8T4

# Compute great-circle distance (in km) between two DIGIPINs
digipin distance 4P3JK852C9 39J49LL8T4
# -> 1740.12 km
```

See the framework's [documentation](https://swiftpackageindex.com/vamsii777/DIGIPIN/documentation) for detailed information and guides.

## 📍 Geographic Coverage

The system covers India's entire territory (EPSG:4326 / WGS84):
- **Latitude**: `2.5°N` to `38.5°N`
- **Longitude**: `63.5°E` to `99.5°E`

Including mainland India, Andaman and Nicobar Islands, Lakshadweep Islands, and the maritime Exclusive Economic Zone (EEZ).

## 📚 Official Standards References

- [Official India Post DIGIPIN Repository (`INDIAPOST-gov/digipin`)](https://github.com/INDIAPOST-gov/digipin)
- [DIGIPIN Technical Specification & Architecture Standard — May 2026 Revision (v2.0.0)](https://github.com/INDIAPOST-gov/digipin/blob/main/docs/DIGIPIN_Technical_Document.md)

## 🤝 Contributing

We appreciate your contributions to make DIGIPIN better! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting a pull request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Department of Posts (India Post), IIT Hyderabad, and NRSC/ISRO for developing the DIGIPIN system
- The Swift community
