# Changelog

## [3.0.0] - 2026-11-25

### Breaking Change
- **100% compliant with the India Post DIGIPIN Technical Specification & Architecture Standard — Version 2.0.0 (May 2026 Standards Revision)** ([INDIAPOST-gov/digipin](https://github.com/INDIAPOST-gov/digipin)).
- `generateDIGIPIN` now emits the canonical **continuous 10-character uppercase string** (e.g., `39J49LL8T4`) without hyphens (§2b, §2c).
- `coordinate(from:)`, `distance(from:to:)`, and `bulkDecode(_:)` now enforce **strict May 2026 validation** by default: leading/trailing whitespace is trimmed, ASCII letters are normalized to uppercase, and hyphens, interior spaces, and non-approved characters are rejected.

### Added
- `DIGIPINValidationMode` (`.strict` default and `.lenient` opt-in for migrating legacy `3-3-4` hyphenated and official `3-4-3` spaced display codes).
- `DIGIPIN.isValid(_:mode:)` validation helper.
- `DIGIPIN.normalize(_:mode:)` helper for migrating legacy hyphenated or display-formatted DIGIPINs to canonical 10-character format.
- `DIGIPIN.formatForDisplay(_:mode:)` helper for official May 2026 §2(c) `3-4-3` space-grouped display formatting (`39J 49LL 8T4`).
- CLI flags `--display` (on `encode`/`normalize`), `--lenient` (on `decode`/`distance`), and new `normalize` subcommand.
- `LocalizedError` conformance on `DIGIPINError`; `Hashable` and `Codable` conformances on `Coordinate`.
- Exhaustive edge-case unit tests (§4.4 grid-line tie-breaking, corner boundaries, `NaN`/`±Infinity`, Unicode/fullwidth rejections, and 100% parity verification against official `INDIAPOST-gov/digipin/src/digipin.js`).

### Fixed
- Fixed `DIGIPINCLITests` executable lookup (`digipin` instead of `digipin-cli`) so CLI integration tests run instead of skipping.
- Added explicit `isFinite` coordinate validation and O(1) ASCII grid lookup.
- Clamped Haversine radicand in `DIGIPIN.distance(from:to:)` to prevent `NaN` on antipodal coordinates.
- Updated documentation links to `INDIAPOST-gov/digipin` and fixed duplicate README badge.

---

## [2.3.0] - 2026-04-01

### Added
- Swift 6 `Sendable` conformance across `DIGIPIN`, `Coordinate`, and `DIGIPINError`.
- CI matrix updates for Xcode 16 / Swift 6.

---

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
- The DIGIPIN implementation is now **fully compliant** with the official India Post specification (March 2025 v1.0.0).
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
