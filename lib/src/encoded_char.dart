// ignore_for_file: public_member_api_docs, sort_constructors_first

part of 'segment_element.dart';

// =============================================================================
// CLASS: EncodedChar
// PURPOSE: Represents a character with its encoded representation based on
// different encoding types (GSM-7 or UCS-2). Provides utility methods to
// calculate the size of encoded characters in bits.
// =============================================================================
class EncodedChar extends SegmentElement {
  String? raw; // Raw character (grapheme)
  List<int>? codeUnits; // Encoded representation of the character
  bool? isGSM7; // True if the character is GSM7, false otherwise
  SmsEncoding? encoding; // Encoding type, either 'GSM-7' or 'UCS-2'

  /// Constructor for the EncodedChar class.
  /// Initializes the raw character, determines its encoding type, and sets its code units.
  ///
  /// [char] : The character to be encoded.
  /// [encoding] : The encoding type name ('GSM-7' or 'UCS-2').
  EncodedChar(String? char, this.encoding) {
    raw = char; // Initialize the raw character

    // Determine if the character is GSM7
    isGSM7 = ((char.notNullNorEmpty) &&
        (char?.length == 1) &&
        unicodeToGsm.containsKey(char?.codeUnitAt(0)));

    // Assign code units based on whether the character is GSM7 or not
    if (isGSM7 ?? false) {
      codeUnits = unicodeToGsm[char?.codeUnitAt(0)]; // Use mapped code units for GSM7
    } else {
      codeUnits = []; // For non-GSM7 characters, initialize an empty list
      for (var i = 0; i < char!.length; i++) {
        codeUnits?.add(char.codeUnitAt(i)); // Add UCS-2 code units
      }
    }
  }

  /// Returns the size of a single code unit in bits.
  ///
  /// Returns:
  /// - 7 bits for 'gsm7' encoding.
  /// - 8 bits for other encodings.
  @override
  int codeUnitSizeInBits() => encoding == SmsEncoding.gsm7 ? 7 : 8;

  /// Calculates the total size in bits of the encoded character.
  ///
  /// Returns:
  /// - 16 bits if the encoding is 'ucs2' and the character is GSM7.
  /// - Otherwise, calculates bits based on encoding type.
  @override
  int sizeInBits() {
    if (encoding == SmsEncoding.ucs2 && (isGSM7 ?? false)) {
      return 16; // UCS-2 encoding, size is 16 bits
    }
    final bitsPerUnits = encoding == SmsEncoding.gsm7 ? 7 : 16; // Bits per unit depending on encoding
    return bitsPerUnits * codeUnits!.length; // Total size in bits
  }
}
