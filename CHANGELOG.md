## 1.1.2

### Fixed
- **CI/CD: skip example directory during publish** — The `example/` folder is a Flutter project which caused `dart pub get` to fail with exit code 69. CI now uses `--no-example` for dependency resolution and scopes format/analyze to `lib/` and `test/` only.

## 1.1.1

### Fixed
- **Replaced `flutter_lints` with `lints`** — The `flutter_lints` dev dependency pulled in the Flutter SDK, causing `dart pub publish` to fail on CI with exit code 69. Replaced with the pure Dart `lints` package.

## 1.1.0

### Breaking Changes
- **Converted to a pure Dart package** — Removed Flutter SDK dependency (`flutter`, `flutter_test`), making the package usable in any Dart project (CLI, server-side, Flutter, etc.).
- **Renamed `SmsEncoding` enum to `SmsEncodingMode`** — The previous `SmsEncoding` enum (with `gsm7`, `ucs2`, `auto`) is now `SmsEncodingMode`. A new `SmsEncoding` enum (with `gsm7`, `ucs2` only) represents the resolved encoding.
- **Removed `ValidEncodingValues` enum** — Replaced by the new `SmsEncoding` enum.
- **Replaced string-based encoding with enums** — `EncodedChar` now uses `SmsEncoding` enum instead of raw strings like `'gsm7'` / `'ucs2'`.

### Added
- **Introduced `SegmentElement` sealed class** — A new base type for `EncodedChar` and `UserDataHeader`, enabling type-safe segment composition and proper polymorphism.
- **Added new test cases** — Tests for long GSM-7 multi-segment messages and long UCS-2 multi-segment messages.
- **Added `toString()` override on `Segment`** — Useful for debugging segment details.
- **Added `repository`, `issue_tracker`, and `topics` metadata** to `pubspec.yaml` for better pub.dev discoverability.

### Changed
- **Replaced `grapheme_splitter` dependency with `characters`** — Uses the official Dart `characters` package for grapheme splitting, reducing dependency bloat.
- **Replaced `flutter_test` with `test` package** — Tests now use the standard Dart `test` package.
- **Type-safe segment elements** — `Segment._elements` changed from `List<dynamic>` to `List<SegmentElement>`, `add()` and `removeLast()` now use `SegmentElement` type.
- **Simplified line break processing** — Grapheme line break handling now uses `expand()` instead of `fold()`.
- **Simplified `_hasAnyUCSCharacters`** — Refactored from a verbose loop to a concise `any()` expression.
- **Improved `sizeInBits()` calculations** — `Segment.sizeInBits()` now correctly sums all element sizes (previously ignored `UserDataHeader` sizes in computation).
- **Fixed `addHeader()` bug** — `hasUserDataHeader` is now correctly set to `true` (was previously set to `false` by mistake).
- **Fixed typo in filename** — Renamed `enchoded_char.dart` to `encoded_char.dart`.
- **Code cleanup** — Replaced `var`/explicit types with `final` where appropriate, used expression body syntax, and improved formatting throughout.

### Removed
- **Removed `grapheme_splitter` dependency** — Replaced by the `characters` package.
- **Removed Flutter SDK dependency** — Package is now pure Dart.

## 1.0.10

### Changed
- fix: importing issue fixed

## 1.0.9

### Changed 
- fix : removed unused functions
- fix : removed unused variables
- fix : removed unused imports
- fix : Code format and refractor 


## 1.0.8

### Changed 
- fix : segment calculation logics
- improved usability
- fix : encoding logic
- Updated the README with detailed descriptions and usage examples.

##  1.0.7

### Changed 
- Code format and refractor

## 0.0.7

### Added
- Added the `SegmentedMessage` class to handle the segmentation logic for dividing a message into multiple SMS segments.
- Added the `EncodedChar` class to represent individual characters and their encoding properties.
- Added the `Segment` class to manage individual segments, handle additions and removals, and calculate segment sizes.
- Added the `UserDataHeader` class to represent the User Data Header required for concatenated SMS messages.
- Enabled `public_member_api_docs` lint to ensure all public API members are documented.
- Introduced example usage in README for easy integration.

### Changed
- Improved error handling in the main entry point for better debugging and usability.
- Updated the README with detailed descriptions and usage examples.


## 0.0.1

* TODO: Describe initial release.




