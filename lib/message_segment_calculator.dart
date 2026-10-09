/// The SMS Segment Calculator package.
///
/// This package provides tools to calculate the number of SMS segments required for messages,
/// supporting both GSM-7 and UCS-2 encoding standards, and the billing of RCS
/// messages.
library sms_segment_calculator;

export 'src/rcs_segmented_message.dart';
export 'src/segmented_message.dart';
export 'src/utils/smart_encoding_map.dart';
export 'src/utils/text_utils.dart' show countUtf8Bytes;
export 'src/utils/unicode_to_gsm.dart';
