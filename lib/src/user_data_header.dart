part of 'segment_element.dart';

/// Represents a User Data Header.
/// A User Data Header (UDH) is a portion of the header of an SMS message that can contain additional information,
/// such as message concatenation, special handling, or other service-specific data.
/// For concatenated messages, Twilio reserves 6 user data headers per segment.
class UserDataHeader extends SegmentElement {
  /// Indicates if the header is a reserved character. This is typically set to `true` for user data headers.
  bool? isReservedChar;

  /// Indicates if this object represents a user data header. This is always set to `true`.
  bool? isUserDataHeader;

  /// Creates a new instance of [UserDataHeader].
  /// Initializes the object properties to indicate it is a reserved character and a user data header.
  UserDataHeader() {
    isReservedChar = true; // Set to true because user data headers are reserved characters.
    isUserDataHeader = true; // Explicitly marks this object as a user data header.
  }

  /// Returns the size of a code unit in bits for user data headers.
  ///
  /// This is a static method because the size of a code unit for a user data header is always 8 bits,
  /// regardless of the specific instance.
  ///
  /// Returns 8, indicating that user data headers use 8 bits per code unit.
  @override
  int codeUnitSizeInBits() => 8;

  /// Returns the total size in bits of the user data header.
  ///
  /// Since each user data header has a fixed size, this method always returns 8 bits.
  ///
  /// Returns 8, indicating the fixed size of the user data header in bits.
  @override
  int sizeInBits() => 8;
}
