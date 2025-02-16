<div align="center">
    <h1>DIGIPIN</h1>
    <a href="https://swiftpackageindex.com/vamsii777/DIGIPIN/documentation">
        <img src="https://img.shields.io/badge/read_the-docs-2ea44f?logo=readthedocs&logoColor=white" alt="Documentation">
    </a>
    <a href="LICENSE">
        <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License">
    </a>
    <a href="https://github.com/vamsii777/DIGIPIN/actions/workflows/test.yml">
        <img src="https://img.shields.io/github/actions/workflow/status/vamsii777/DIGIPIN/test.yml?event=push&style=flat&logo=github&label=tests" alt="Continuous Integration">
    </a>
    <a href="https://swift.org">
        <img src="https://img.shields.io/badge/swift-5.8%2B-orange.svg" alt="Swift 5.8+">
    </a>
</div>
<br>

🌍 📍 A Swift library for handling India Post's DIGIPIN (Digital Postal Index Number) system - encode any location in India into a simple 10-character code.

Use the SPM string to easily include the dependency in your `Package.swift` file:

```swift
.package(url: "https://github.com/vamsii777/DIGIPIN.git", from: "1.0.0")
```

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
let coordinate = Coordinate(latitude: 28.6139, longitude: 77.2090) // New Delhi

do {
    let code = try digipin.generateDIGIPIN(for: coordinate)
    print(code) // Outputs formatted DIGIPIN code
} catch {
    print("Error: \(error)")
}

// Convert back to coordinates
do {
    let location = try digipin.coordinate(from: "ABC-DEF-GHIJ")
    print("Lat: \(location.latitude), Long: \(location.longitude)")
} catch {
    print("Error: \(error)")
}
```

See the framework's [documentation](https://swiftpackageindex.com/vamsii777/DIGIPIN/documentation) for detailed information and guides.

## 📍 Geographic Coverage

The system covers India's entire territory:
- Latitude: 1.5°N to 39.0°N
- Longitude: 63.5°E to 99.0°E

Including:
- Mainland India
- Andaman and Nicobar Islands
- Lakshadweep Islands
- Buffer zones

For technical details about the DIGIPIN system, see:
- [Official DIGIPIN Technical Documentation](https://www.indiapost.gov.in/Navigation_Documents/Static_Navigation/DIGIPIN%20Technical%20Document%20Final%20English.pdf)
- [India Post DIGIPIN Portal](https://www.indiapost.gov.in)



## 🤝 Contributing

We appreciate your contributions to make DIGIPIN better! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting a pull request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- India Post for developing the DIGIPIN system
- The Swift community
