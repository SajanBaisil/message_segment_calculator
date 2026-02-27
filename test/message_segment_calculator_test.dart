import 'package:test/test.dart';
import 'package:message_segment_calculator/src/segment_element.dart';
import 'package:message_segment_calculator/src/segmented_message.dart';
import 'package:message_segment_calculator/src/segment.dart';

void main() {
  group('SegmentedMessage Tests', () {
    test('Calculates correct segments for a simple GSM-7 message', () {
      const message = 'Hello, this is a test message!';
      SegmentedMessage segmentedMessage = SegmentedMessage(message);

      expect(segmentedMessage.segmentsCount, 1);
      expect(segmentedMessage.totalSize, lessThanOrEqualTo(1120)); // 1 segment
      expect(segmentedMessage.encoding, SmsEncoding.gsm7);
    });

    test('Calculates correct segments for a long GSM-7 message', () {
      const message =
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolor';
      SegmentedMessage segmentedMessage = SegmentedMessage(message);

      expect(segmentedMessage.segmentsCount, 3);
      expect(segmentedMessage.totalSize, lessThanOrEqualTo(2293)); // 1 segment
      expect(segmentedMessage.encoding, SmsEncoding.gsm7);
    });

    test('Calculates correct segments for a long UCS-2 message', () {
      const message =
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolorç';
      SegmentedMessage segmentedMessage = SegmentedMessage(message);

      expect(segmentedMessage.segmentsCount, 5);
      expect(segmentedMessage.totalSize, lessThanOrEqualTo(5168)); // 1 segment
      expect(segmentedMessage.encoding, SmsEncoding.ucs2);
    });

    test('Calculates correct segments for a message with emojis', () {
      const message = 'Hello 😊! This message contains emojis.';
      SegmentedMessage segmentedMessage = SegmentedMessage(message);

      expect(segmentedMessage.segmentsCount, greaterThanOrEqualTo(1));
      expect(segmentedMessage.encoding, SmsEncoding.ucs2);
    });

    test('Handles UCS-2 encoding for special characters', () {
      const message = 'こんにちは世界'; // Japanese for "Hello, World"
      SegmentedMessage segmentedMessage = SegmentedMessage(message);

      expect(segmentedMessage.encoding, SmsEncoding.ucs2);
      expect(segmentedMessage.segmentsCount, greaterThanOrEqualTo(1));
    });

    test('Throws exception for incompatible GSM-7 characters', () {
      const message = 'Hello 😊!';

      expect(
        () => SegmentedMessage(message, SmsEncodingMode.gsm7),
        throwsException,
      );
    });

    test('Detects line break styles correctly', () {
      const message = 'Hello\nWorld\r\nNew Line';

      SegmentedMessage segmentedMessage = SegmentedMessage(message);

      expect(segmentedMessage.lineBreakStyle, LineBreakStyle.lfCrlf);
    });

    test('Identifies non-GSM characters', () {
      const message = 'Hello 😊!';

      SegmentedMessage segmentedMessage = SegmentedMessage(message);
      List<String?> nonGsmChars = segmentedMessage.getNonGsmCharacters();

      expect(nonGsmChars.isNotEmpty, true);
    });
  });

  group('EncodedChar Tests', () {
    test('Creates EncodedChar correctly for GSM-7 character', () {
      final encodedChar = EncodedChar('A', SmsEncoding.gsm7);

      expect(encodedChar.isGSM7, true);
      expect(encodedChar.codeUnits?.length, 1);
      expect(encodedChar.sizeInBits(), 7);
    });

    test('Creates EncodedChar correctly for UCS-2 character', () {
      final encodedChar = EncodedChar('😊', SmsEncoding.ucs2);

      expect(encodedChar.isGSM7, false);
      expect(encodedChar.codeUnits?.length, greaterThanOrEqualTo(1));
      expect(encodedChar.sizeInBits(), greaterThan(7));
    });
  });

  group('Segment Tests', () {
    test('Calculates free size correctly after adding characters', () {
      final segment = Segment();
      final char = EncodedChar('A', SmsEncoding.gsm7);
      segment.add(char);

      expect(segment.freeSizeInBits(), lessThan(1120));
    });

    test('Adds headers correctly and manages overflow', () {
      final segment = Segment();
      final char = EncodedChar('A', SmsEncoding.gsm7);
      segment.add(char);
      final overflow = segment.addHeader();

      expect(segment.hasUserDataHeader, true);
      expect(segment.elements.length, greaterThan(1)); // Includes headers
      expect(overflow, isEmpty); // No overflow if only one char added
    });
  });

  group('UserDataHeader Tests', () {
    test('Calculates size in bits correctly for UserDataHeader', () {
      final header = UserDataHeader();

      expect(header.sizeInBits(), 8);
    });
  });

  group('remainingCharsInSegment & maxCharsPerSegment Tests', () {
    test('Empty GSM-7 message: 160 max, 160 remaining', () {
      final msg = SegmentedMessage('');
      expect(msg.encoding, SmsEncoding.gsm7);
      expect(msg.maxCharsPerSegment, 160);
      expect(msg.remainingCharsInSegment, 160);
    });

    test('Short GSM-7 message: 160 max, remaining = 160 - length', () {
      const text = 'Hello'; // 5 chars, 5 code units in GSM-7
      final msg = SegmentedMessage(text);

      expect(msg.encoding, SmsEncoding.gsm7);
      expect(msg.segmentsCount, 1);
      expect(msg.maxCharsPerSegment, 160);
      expect(msg.remainingCharsInSegment, 155);
    });

    test('Exactly 160 GSM-7 chars: 1 segment, 0 remaining', () {
      final text = 'A' * 160;
      final msg = SegmentedMessage(text);

      expect(msg.encoding, SmsEncoding.gsm7);
      expect(msg.segmentsCount, 1);
      expect(msg.maxCharsPerSegment, 160);
      expect(msg.remainingCharsInSegment, 0);
    });

    test('161 GSM-7 chars: 2 segments, maxCharsPerSegment = 153', () {
      final text = 'A' * 161;
      final msg = SegmentedMessage(text);

      expect(msg.encoding, SmsEncoding.gsm7);
      expect(msg.segmentsCount, 2);
      expect(msg.maxCharsPerSegment, 153);
      // 2 segments × 153 = 306 capacity, used 161, remaining in last segment
      expect(msg.remainingCharsInSegment, 153 - (161 - 153));
    });

    test('Short UCS-2 message: 70 max, remaining correct', () {
      const text = 'こんにちは'; // 5 UCS-2 chars
      final msg = SegmentedMessage(text);

      expect(msg.encoding, SmsEncoding.ucs2);
      expect(msg.segmentsCount, 1);
      expect(msg.maxCharsPerSegment, 70);
      expect(msg.remainingCharsInSegment, 65);
    });

    test('Exactly 70 UCS-2 chars: 1 segment, 0 remaining', () {
      final text = 'あ' * 70;
      final msg = SegmentedMessage(text);

      expect(msg.encoding, SmsEncoding.ucs2);
      expect(msg.segmentsCount, 1);
      expect(msg.maxCharsPerSegment, 70);
      expect(msg.remainingCharsInSegment, 0);
    });

    test('71 UCS-2 chars: 2 segments, maxCharsPerSegment = 67', () {
      final text = 'あ' * 71;
      final msg = SegmentedMessage(text);

      expect(msg.encoding, SmsEncoding.ucs2);
      expect(msg.segmentsCount, 2);
      expect(msg.maxCharsPerSegment, 67);
      // 2 segments × 67 = 134 capacity, used 71, remaining in last segment
      expect(msg.remainingCharsInSegment, 67 - (71 - 67));
    });

    test('GSM-7 extended char (backslash) uses 2 code units', () {
      // Backslash is an extended GSM-7 char → 2 code units → 14 bits
      const text = r'Hello\'; // 5 normal + 1 extended (2 code units)
      final msg = SegmentedMessage(text);

      expect(msg.encoding, SmsEncoding.gsm7);
      expect(msg.segmentsCount, 1);
      // 5 normal chars = 35 bits, 1 extended = 14 bits → total 49 bits
      // remaining = (1120 - 49) ~/ 7 = 153
      expect(msg.remainingCharsInSegment, 153);
    });
  });
}
