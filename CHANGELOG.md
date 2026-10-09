## 1.3.0

Brings the package in line with Twilio's official calculator
([TwilioDevEd/message-segment-calculator](https://github.com/TwilioDevEd/message-segment-calculator) v1.3.0).
Verified by running both calculators on more than 10,000 messages (emoji, flags,
skin tones, ZWJ sequences, accents, CJK, GSM-7 extension characters, line
breaks, smart encoding, forced encodings) and comparing every output; they
agree on all of them.

### Fixed

- **Grapheme splitting now matches Twilio** — Replaced `package:characters`
  with a Dart port of grapheme-splitter 1.0.4, the splitter Twilio uses. Newer
  emoji sequences (e.g. 🏴‍☠️, 🫱🏼‍🫲🏿, 🐦‍🔥) are split the same way, so the
  character and segment counts are the same as Twilio's.
- **Spaces and line breaks were reported as non-GSM** — `EncodedChar.isGSM7`
  trimmed the character before checking it, so `' '`, `'\n'` and `'\r'` were
  `false` and showed up in `getNonGsmCharacters()`.
- **GSM extension characters in UCS-2 messages** — `|`, `^`, `{`, `€`, … now
  keep their single UTF-16 code unit in `codeUnits` when the message is UCS-2,
  instead of the 2-unit GSM-7 escape sequence (Twilio #57/#61).
- **Line break style** — A message with only CRLF line breaks is now reported
  as `LineBreakStyle.crlf` instead of `lfCrlf` (Twilio #67).
- **Smart encoding** — `‹` and `›` now map to `<` and `>` (they were swapped,
  Twilio #58), and ZERO WIDTH NON-JOINER (U+200C) is removed. Smart encoding
  now iterates Unicode code points, like Twilio.
- **Line break warning** now uses Twilio's exact wording.
- `Segment.addHeader()` sets `hasUserDataHeader` to `false` like Twilio
  (`hasTwilioReservedBits` is `true`). Segment counts are unaffected.

### Added

- **`RcsSegmentedMessage`** — RCS billing (UTF-8 bytes): US messages are split
  into 160-byte "Rich" segments; international messages are "Basic"
  (≤160 bytes) or "Single" (>160 bytes, capacity 1600).
- **`countUtf8Bytes()`** — UTF-8 byte length of a message.
- Port of Twilio's full test suite (`test/twilio_parity_test.dart`).

### Changed

- The package no longer depends on `package:characters`.

## 1.2.0

### Added

- **`remainingCharsInSegment` property** — Returns how many characters can still be added to the current (last) segment before a new segment is created. Useful for building real-time character counters and SMS cost previews.
- **`maxCharsPerSegment` property** — Returns the maximum number of characters that fit in a single segment for the current encoding. Accounts for the User Data Header overhead in multi-segment messages (GSM-7: 160→153, UCS-2: 70→67).
- **8 new unit tests** — Comprehensive tests covering empty messages, exact boundary, single/multi-segment transitions, and extended GSM-7 characters for both new properties.

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

## 1.0.7

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

- TODO: Describe initial release.
