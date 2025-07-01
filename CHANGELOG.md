# Changelog

## [2.2.0] - 2025-07-02

### Added
- Bulk encode (`bulkEncode`) and bulk decode (`bulkDecode`) API to the DIGIPIN library for efficient batch operations.
- Unit tests for bulk encode and decode, covering valid, invalid, and mixed input cases.

### Changed
- Improved error handling for batch operations in the DIGIPIN library.

---

## [2.1.0] - 2025-07-01

### Added
- CLI tool (`digipin`) for encoding, decoding, and distance calculation.
- Public distance calculation API to the DIGIPIN library.
- CLI integration tests for encode, decode, and distance commands.
- Swift 6 concurrency compliance for CLI and library.

### Changed
- Improved documentation and usage examples for CLI and distance features.
- Updated test targets and structure for CLI integration.

### Fixed
- Fixed SwiftPM test discovery for CLI tests.
- Fixed concurrency warnings in CLI code for Swift 6.

---

## [2.0.0] - 2025-06-30

### Breaking Change
- The DIGIPIN implementation is now **fully compliant** with the official India Post specification ([Technical Document](https://www.indiapost.gov.in/VAS/DOP_PDFFiles/DIGIPIN%20Technical%20document.pdf)).
- Previous versions (including `1.0.0`) may generate incompatible codes. All users should upgrade to this version for official compatibility.

### Added
- Official grid, bounds, and encoding/decoding logic as per India Post.
- Updated documentation, usage examples, and developer guide.
- Additional unit tests for official and edge-case examples.

### Changed
- Refactored code for clarity, immutability, and best Swift practices.
- Improved error messages and type safety.

### Fixed
- Corrected grid, bounds, and logic to match the official DIGIPIN system.

---

## [1.0.0] - 2025-02-17

### Added
- Initial release of the DIGIPIN Swift library.
- Encode latitude/longitude to DIGIPIN and decode DIGIPIN to coordinates.
- Input validation and error handling.
- Documentation and usage examples.
- Unit tests for basic functionality.

### Note
- This version was **not fully compliant** with the official India Post DIGIPIN specification. Users should upgrade to `2.0.0` or later for official compatibility.

--- 