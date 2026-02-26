import 'package:characters/characters.dart';
import 'package:message_segment_calculator/message_segment_calculator.dart';

import 'segment_element.dart';
import 'segment.dart';

/// =============================================================================
/// ENUM: SmsEncodingMode
/// PURPOSE: Specifies the encoding types that can be used for SMS messages.
/// =============================================================================
enum SmsEncodingMode {
  /// Represents the GSM-7 encoding, a 7-bit encoding standard used for SMS messages.
  gsm7,

  /// Represents the UCS-2 encoding, a 16-bit encoding standard used for SMS messages that include non-GSM-7 characters.
  ucs2,

  /// Automatically determines the best encoding based on the content of the SMS message.
  auto,
}

/// =============================================================================
/// ENUM: SmsEncoding
/// PURPOSE: Specifies the encoding types for a SMS messages.
/// =============================================================================
enum SmsEncoding {
  /// Represents the GSM-7 encoding, a 7-bit encoding standard used for SMS messages.
  gsm7,

  /// Represents the UCS-2 encoding, a 16-bit encoding standard used for SMS messages that include non-GSM-7 characters.
  ucs2,
}

/// =============================================================================
/// ENUM: LineBreakStyle
/// PURPOSE: Defines different styles for line breaks in text messages.
/// =============================================================================
enum LineBreakStyle {
  /// Represents 'LF' (Line Feed)
  lf,

  /// Represents 'CRLF' (Carriage Return + Line Feed)
  crlf,

  /// Represents 'LF+CRLF' (Combination of LF and CRLF)
  lfCrlf,

  /// Undefined or no line break style
  undefined
}

/// =============================================================================
/// CLASS: SegmentedMessage
/// PURPOSE: Manages the segmentation and encoding of SMS messages based on
/// specified encoding formats. It supports encoding into GSM-7 and UCS-2
/// character sets and can handle different line break styles.
/// =============================================================================
class SegmentedMessage {
  /// Encoding mode format for the SMS message, defaults to auto-detection
  SmsEncodingMode encodingMode = SmsEncodingMode.auto;

  /// Actual encoding used for the SMS message after processing
  late SmsEncoding encoding;

  /// List of segments created for the SMS message
  List<Segment> segments = [];

  /// List of graphemes in the message
  List<String> graphemes = [];

  /// Total number of Unicode scalars in the message
  int numberOfUnicodeScalars = 0;

  /// Total number of characters in the message
  int numberOfCharacters = 0;

  /// Encoded characters after processing the message content
  List<EncodedChar> encodedChars = [];

  /// Style of line breaks in the message
  LineBreakStyle? lineBreakStyle;

  /// List of warnings detected during message processing
  List<String> warnings = [];

  /// Constructor for the SegmentedMessage class.
  ///
  /// [message] : The message content to be segmented and encoded.
  /// [encodingMode] : The desired encoding format (defaults to auto-detection).
  /// [smartEncoding] : Whether to use smart encoding for character replacement.
  SegmentedMessage(String message, [this.encodingMode = SmsEncodingMode.auto, bool smartEncoding = false]) {
    // Apply smart encoding if enabled
    if (smartEncoding) {
      message = message.split('').map((char) => smartEncodingMap[char] ?? char).join('');
    }

    // Split message into graphemes and process line breaks
    graphemes = message.characters.expand((grapheme) => grapheme == '\r\n' ? grapheme.split('') : [grapheme]).toList(growable: false);

    // Count the number of Unicode scalars in the message
    numberOfUnicodeScalars = message.runes.length;

    // Determine the encoding type for the message
    if (encodingMode == SmsEncodingMode.auto) {
      encoding = _hasAnyUCSCharacters(graphemes) ? SmsEncoding.ucs2 : SmsEncoding.gsm7;
    } else {
      if (encodingMode == SmsEncodingMode.gsm7 && _hasAnyUCSCharacters(graphemes)) {
        throw Exception('The string provided is incompatible with GSM-7 encoding');
      }
      encoding = switch(encodingMode) {
        SmsEncodingMode.gsm7 => SmsEncoding.gsm7,
        SmsEncodingMode.ucs2 => SmsEncoding.ucs2,
        _ => throw ('Unsupported encoding mode: $encodingMode'),
      };
    }

    // Encode the characters based on the determined encoding
    encodedChars = _encodeChars(graphemes, encoding);

    // Count the number of characters based on encoding
    numberOfCharacters = encoding == SmsEncoding.ucs2
        ? graphemes.length
        : _countCodeUnits(encodedChars);

    // Build segments from encoded characters
    segments = _buildSegments(encodedChars);

    // Detect the line break style in the message
    lineBreakStyle = _detectLineBreakStyle(message);

    // Check for any warnings in the message content
    warnings = _checkForWarnings(lineBreakStyle);
  }

  /// Method to encode each character in the message to its encoded representation.
  ///
  /// [graphemes] : List of graphemes in the message.
  /// [encoding] : The encoding name ('gsm7' or 'ucs2').
  ///
  /// Returns a list of encoded characters.
  List<EncodedChar> _encodeChars(List<String> graphemes, SmsEncoding encoding) {
    List<EncodedChar> encodedChars = [];

    for (String grapheme in graphemes) {
      encodedChars.add(EncodedChar(grapheme, encoding));
    }

    return encodedChars;
  }

  /// Builds segments for the message by distributing characters into SMS segments.
  ///
  /// [encodedChars] : List of encoded characters.
  ///
  /// Returns a list of message segments.
  List<Segment> _buildSegments(List<EncodedChar> encodedChars) {
    List<Segment> segments = [];
    segments.add(Segment());
    Segment currentSegment = segments[0];

    /// Iterate over each encoded character and add it to the appropriate segment
    for (final encodedChar in encodedChars) {
      if (currentSegment.freeSizeInBits() < encodedChar.sizeInBits()) {
        segments.add(Segment(withUserDataHeader: true));
        currentSegment = segments[segments.length - 1];
        Segment previousSegment = segments[segments.length - 2];

        if (!previousSegment.hasUserDataHeader) {
          final removedChars = previousSegment.addHeader();
          for (final char in removedChars) {
            currentSegment.add(char);
          }
        }
      }
      currentSegment.add(encodedChar);
    }

    return segments;
  }

  /// Counts the total number of code units in the message.
  ///
  /// [encodedChars] : List of encoded characters.
  ///
  /// Returns the total number of code units.
  int _countCodeUnits(List<EncodedChar> encodedChars) {
    return encodedChars.fold<int>(
      0,
      (int accumulator, EncodedChar nextEncodedChar) =>
          accumulator + nextEncodedChar.codeUnits!.length,
    );
  }

  /// Calculates the total size in bits of the entire message.
  ///
  /// Returns the total size in bits of the message including headers.
  int get totalSize {
    int size = 0;
    for (Segment segment in segments) {
      size += segment.sizeInBits();
    }
    return size;
  }

  /// Calculates the message size in bits, excluding any user data headers.
  ///
  /// Returns the message size in bits without headers.
  int get messageSize {
    int size = 0;

    for (var segment in segments) {
      size += segment.messageSizeInBits();
    }

    return size;
  }

  /// Gets the number of segments in the message.
  int get segmentsCount => segments.length;

  /// Retrieves a list of characters that are not GSM-7 encoded.
  ///
  /// Returns a list of non-GSM7 characters.
  List<String?> getNonGsmCharacters() {
    return encodedChars
        .where((encodedChar) => !(encodedChar.isGSM7 ?? false))
        .map((encodedChar) => encodedChar.raw)
        .toList();
  }

  /// Detects the line break style used in the message.
  ///
  /// [message] : The message content.
  ///
  /// Returns the line break style used (LF, CRLF, LF+CRLF, or null).
  LineBreakStyle? _detectLineBreakStyle(String message) {
    bool hasWindowsStyle = message.contains('\r\n');
    bool hasUnixStyle = message.contains('\n');
    bool mixedStyle = hasWindowsStyle && hasUnixStyle;
    bool noBreakLine = !hasWindowsStyle && !hasUnixStyle;

    if (noBreakLine) {
      return null;
    }
    if (mixedStyle) {
      return LineBreakStyle.lfCrlf;
    }
    return hasUnixStyle ? LineBreakStyle.lf : LineBreakStyle.crlf;
  }

  /// Checks for any warnings in the message content.
  ///
  /// [lineBreakStyle] : The line break style detected in the message.
  ///
  /// Returns a list of warnings detected.
  List<String> _checkForWarnings(LineBreakStyle? lineBreakStyle) {
    List<String> warnings = [];

    if (lineBreakStyle != null) {
      warnings.add(
        'The message has line breaks; the web page utility only supports LF style. If you insert a CRLF, it will be converted to LF.',
      );
    }

    return warnings;
  }

  /// Checks if the message contains any UCS-2 characters.
  ///
  /// [graphemes] : List of graphemes in the message.
  ///
  /// Returns true if any character requires UCS-2 encoding, otherwise false.
  bool _hasAnyUCSCharacters(List<String> graphemes) =>
      graphemes.any((grapheme) => grapheme.length >= 2 || (grapheme.length == 1 && !unicodeToGsm.containsKey(grapheme.codeUnitAt(0))));
}
