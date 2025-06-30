# DIGIPIN Developer Guide

## Introduction

DIGIPIN (Digital Postal Index Number) is a standardized, geo-coded addressing system for India, developed by India Post. This guide explains how to use the production-grade Swift DIGIPIN library to encode and decode locations, and how to ensure compliance with the official specification.

## Key Concepts

- **Grid System**: DIGIPIN divides India's territory into a hierarchical grid of 4x4 cells at each of 10 levels, using the same grid for all levels:

```
[
  ["F", "C", "9", "8"],
  ["J", "3", "2", "7"],
  ["K", "4", "5", "6"],
  ["L", "M", "P", "T"]
]
```

- **Bounds**: Only coordinates within latitude 2.5°N to 38.5°N and longitude 63.5°E to 99.5°E are valid.
- **Reversed Row Logic**: The row index is calculated as `3 - floor((lat - minLat) / latDiv)` to match the official grid orientation.

## Usage

### Encoding a Coordinate

```swift
let digipin = DIGIPIN()
let coordinate = Coordinate(latitude: 28.622788, longitude: 77.213033)
let code = try digipin.generateDIGIPIN(for: coordinate) // "39J-49L-L8T4"
```

### Decoding a DIGIPIN

```swift
let digipin = DIGIPIN()
let coordinate = try digipin.coordinate(from: "39J-49L-L8T4")
```

## Best Practices

- Always validate input coordinates before encoding.
- Handle errors gracefully using `DIGIPINError`.
- Use the provided unit tests as a reference for expected behavior.
- Refer to the [official DIGIPIN technical document](https://www.indiapost.gov.in/VAS/DOP_PDFFiles/DIGIPIN%20Technical%20document.pdf) for algorithmic details.

## References
- [India Post DIGIPIN Technical Document](https://www.indiapost.gov.in/VAS/DOP_PDFFiles/DIGIPIN%20Technical%20document.pdf)
