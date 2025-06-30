<div align="center">
    <h1>DIGIPIN</h1>
    <a href="https://swift.org">
        <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fvamsii777%2FDIGIPIN%2Fbadge%3Ftype%3Dswift-versions" alt="Swift 5.8">
    </a>
    <a href="https://github.com/vamsii777/DIGIPIN/actions/workflows/test.yml">
        <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fvamsii777%2FDIGIPIN%2Fbadge%3Ftype%3Dswift-versions" alt="Swift 5.8">
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

🌍 📍 A Swift library for handling India Post's DIGIPIN (Digital Postal Index Number) system - encode any location in India into a simple 10-character code.

## 🗺️ Geographic Encoding

The `DIGIPIN` framework provides tools to generate and decode DIGIPIN codes - India Post's revolutionary geographic encoding system. It enables precise location representation through a simple 10-character alphanumeric code, covering all of India's territory with high precision.

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

// Generate a DIGIPIN code
let digipin = DIGIPIN()
let coordinate = Coordinate(latitude: 28.622788, longitude: 77.213033) // Dak Bhawan (official example)

let code = try digipin.generateDIGIPIN(for: coordinate)
print(code) // "39J-49L-L8T4"

// Convert back to coordinates
let location = try digipin.coordinate(from: "39J-49L-L8T4")
print("Lat: \(location.latitude), Long: \(location.longitude)")
```

See the framework's [documentation](https://swiftpackageindex.com/vamsii777/DIGIPIN/documentation) for detailed information and guides.

## 📍 Geographic Coverage

The system covers India's entire territory:
- Latitude: 2.5°N to 38.5°N
- Longitude: 63.5°E to 99.5°E

Including:
- Mainland India
- Andaman and Nicobar Islands
- Lakshadweep Islands
- Buffer zones

For technical details about the DIGIPIN system, see:
- [Official DIGIPIN Technical Documentation](https://www.indiapost.gov.in/VAS/DOP_PDFFiles/DIGIPIN%20Technical%20document.pdf)

## 🤝 Contributing

We appreciate your contributions to make DIGIPIN better! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting a pull request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- India Post for developing the DIGIPIN system
- The Swift community
