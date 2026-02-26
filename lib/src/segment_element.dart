import 'package:message_segment_calculator/message_segment_calculator.dart';
import 'package:message_segment_calculator/src/utils/on_string.dart';

part 'encoded_char.dart';
part 'user_data_header.dart';

/// Represents a segment element in an SMS message.
sealed class SegmentElement {
  /// Returns the size of a single code unit in bits.
  int codeUnitSizeInBits();

  /// Returns the total size in bits
  int sizeInBits();
}
