// Port of the test suite of Twilio's message segment calculator
// (https://github.com/TwilioDevEd/message-segment-calculator/tree/main/tests),
// v1.3.0. Every expectation below is copied from the JavaScript tests.

import 'package:message_segment_calculator/message_segment_calculator.dart';
import 'package:message_segment_calculator/src/segment_element.dart';
import 'package:test/test.dart';

class _TestData {
  const _TestData(
    this.description,
    this.body, {
    required this.encoding,
    required this.segments,
    required this.messageSize,
    required this.totalSize,
    required this.characters,
    required this.unicodeScalars,
  });

  final String description;
  final String body;
  final SmsEncoding encoding;
  final int segments;
  final int messageSize;
  final int totalSize;
  final int characters;
  final int unicodeScalars;
}

const _digits =
    '1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890';

const _testData = [
  _TestData('GSM-7 in one segment',
      '1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890',
      encoding: SmsEncoding.gsm7,
      segments: 1,
      messageSize: 1120,
      totalSize: 1120,
      characters: 160,
      unicodeScalars: 160),
  _TestData('GSM-7 in two segments',
      '12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901',
      encoding: SmsEncoding.gsm7,
      segments: 2,
      messageSize: 1127,
      totalSize: 1223,
      characters: 161,
      unicodeScalars: 161),
  _TestData('GSM-7 in three segments',
      '1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567',
      encoding: SmsEncoding.gsm7,
      segments: 3,
      messageSize: 2149,
      totalSize: 2293,
      characters: 307,
      unicodeScalars: 307),
  _TestData('UCS-2 message in one segment',
      '😜23456789012345678901234567890123456789012345678901234567890123456789',
      encoding: SmsEncoding.ucs2,
      segments: 1,
      messageSize: 1120,
      totalSize: 1120,
      characters: 69,
      unicodeScalars: 69),
  _TestData('UCS-2 message in two segments',
      '😜234567890123456789012345678901234567890123456789012345678901234567890',
      encoding: SmsEncoding.ucs2,
      segments: 2,
      messageSize: 1136,
      totalSize: 1232,
      characters: 70,
      unicodeScalars: 70),
  _TestData('UCS-2 message in three segments',
      '😜2345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234',
      encoding: SmsEncoding.ucs2,
      segments: 3,
      messageSize: 2160,
      totalSize: 2304,
      characters: 134,
      unicodeScalars: 134),
  _TestData('UCS-2 with two bytes extended characters in one segments boundary',
      '🇮🇹234567890123456789012345678901234567890123456789012345678901234567',
      encoding: SmsEncoding.ucs2,
      segments: 1,
      messageSize: 1120,
      totalSize: 1120,
      characters: 67,
      unicodeScalars: 68),
  _TestData('UCS-2 with extended characters in two segments boundary',
      '🇮🇹2345678901234567890123456789012345678901234567890123456789012345678',
      encoding: SmsEncoding.ucs2,
      segments: 2,
      messageSize: 1136,
      totalSize: 1232,
      characters: 68,
      unicodeScalars: 69),
  _TestData(
      'UCS-2 with four bytes extended characters in one segments boundary',
      '🏳️‍🌈2345678901234567890123456789012345678901234567890123456789012345',
      encoding: SmsEncoding.ucs2,
      segments: 1,
      messageSize: 1120,
      totalSize: 1120,
      characters: 65,
      unicodeScalars: 68),
  _TestData(
      'UCS-2 with four bytes extended characters in two segments boundary',
      '🏳️‍🌈23456789012345678901234567890123456789012345678901234567890123456',
      encoding: SmsEncoding.ucs2,
      segments: 2,
      messageSize: 1136,
      totalSize: 1232,
      characters: 66,
      unicodeScalars: 69),
];

/// 'e' followed by three combining acute accents (4 Unicode scalars).
const _tripleAccent = 'e\u0301\u0301\u0301';

const _gsm7EscapeChars = ['|', '^', '€', '{', '}', '[', ']', '~', '\\'];

List<SegmentElement> _elements(SegmentedMessage m, int segment) =>
    m.segments[segment].elements;

void main() {
  group('Smart Encoding', () {
    for (final entry in smartEncodingMap.entries) {
      test('With Smart Encoding enabled - maps ${entry.key} to ${entry.value}',
          () {
        final m = SegmentedMessage(entry.key, SmsEncodingMode.auto, true);
        expect(m.graphemes.join(), entry.value);
      });
      test('With Smart Encoding disabled - does not modify ${entry.key}', () {
        final m = SegmentedMessage(entry.key, SmsEncodingMode.auto, false);
        expect(m.graphemes.join(), entry.key);
      });
    }
    test('Replace all Smart Encoding chars at once', () {
      final m = SegmentedMessage(
          smartEncodingMap.keys.join(), SmsEncodingMode.auto, true);
      expect(m.graphemes.join(), smartEncodingMap.values.join());
    });
    test('Single angle quotation marks map to matching ASCII (#58)', () {
      expect(smartEncodingMap['‹'], '<');
      expect(smartEncodingMap['›'], '>');
    });
  });

  group('Basic tests', () {
    for (final data in _testData) {
      test(data.description, () {
        final m = SegmentedMessage(data.body);
        expect(m.encoding, data.encoding);
        expect(m.segments.length, data.segments);
        expect(m.segmentsCount, data.segments);
        expect(m.messageSize, data.messageSize);
        expect(m.totalSize, data.totalSize);
        expect(m.numberOfUnicodeScalars, data.unicodeScalars);
        expect(m.numberOfCharacters, data.characters);
      });
    }
  });

  group('GSM-7 Escape Characters', () {
    for (final escapeChar in _gsm7EscapeChars) {
      test('One segment with escape character $escapeChar', () {
        final m = SegmentedMessage('$escapeChar${_digits.substring(0, 158)}');
        expect(m.encoding, SmsEncoding.gsm7);
        expect(m.segments.length, 1);
        expect(m.segmentsCount, 1);
        expect(m.messageSize, 1120);
        expect(m.totalSize, 1120);
      });
      test('Two segments with escape character $escapeChar', () {
        final m = SegmentedMessage('$escapeChar${_digits.substring(0, 159)}');
        expect(m.encoding, SmsEncoding.gsm7);
        expect(m.segments.length, 2);
        expect(m.segmentsCount, 2);
        expect(m.messageSize, 1127);
        expect(m.totalSize, 1223);
      });
    }
  });

  group('One grapheme UCS-2 characters', () {
    const testCharacters = ['Á', 'Ú', 'ú', 'ç', 'í', 'Í', 'ó', 'Ó'];
    for (final character in testCharacters) {
      test('One segment, 70 characters of "$character"', () {
        final m = SegmentedMessage(character * 70);
        expect(m.segmentsCount, 1);
        for (final encodedChar in m.encodedChars) {
          expect(encodedChar.isGSM7, false);
        }
      });
      test('Two segments, 71 characters of "$character"', () {
        final m = SegmentedMessage(character * 71);
        expect(m.segmentsCount, 2);
        for (final encodedChar in m.encodedChars) {
          expect(encodedChar.isGSM7, false);
        }
      });
    }
  });

  group('Special tests', () {
    test('UCS2 message with special GSM characters in one segment', () {
      // Issue #18: wrong segmnent calculation using GSM special characters
      expect(SegmentedMessage('😀${']' * 68}').segmentsCount, 1);
    });
    test('UCS2 message with special GSM characters in two segment', () {
      expect(SegmentedMessage('😀${']' * 69}').segmentsCount, 2);
    });
  });

  group('Line break styles tests', () {
    test('Message with CRLF line break style and auto detection', () {
      expect(SegmentedMessage('\rabcde\r\n123').numberOfCharacters, 11);
    });
    test('Message with LF line break style and auto detection', () {
      expect(SegmentedMessage('\nabcde\n\n123\n').numberOfCharacters, 12);
    });
    // Tests for https://github.com/TwilioDevEd/message-segment-calculator/issues/67
    test('lineBreakStyle is null when there are no line breaks', () {
      expect(SegmentedMessage('abcde').lineBreakStyle, isNull);
    });
    test('lineBreakStyle is LF for messages with only Unix line breaks', () {
      expect(SegmentedMessage('abc\ndef').lineBreakStyle, LineBreakStyle.lf);
    });
    test('lineBreakStyle is CRLF for messages with only Windows line breaks',
        () {
      expect(
          SegmentedMessage('abc\r\ndef').lineBreakStyle, LineBreakStyle.crlf);
    });
    test('lineBreakStyle is LF+CRLF for messages that mix both styles', () {
      expect(SegmentedMessage('abc\r\ndef\nghi').lineBreakStyle,
          LineBreakStyle.lfCrlf);
    });
    test('Line break warning text', () {
      expect(SegmentedMessage('a\nb').warnings, [
        'The message has line breaks, the web page utility only supports LF style. If you insert a CRLF it will be converted to LF.',
      ]);
      expect(SegmentedMessage('ab').warnings, isEmpty);
    });
    // Real-world case (via PR #52): the same message costs an extra segment
    // with CRLF because each \r\n counts as 2 characters, pushing it over 160.
    test('Real-world message: CRLF bills 2 segments, LF bills 1', () {
      const crlf =
          "Ce weekend c'est Big Kiff ! Découvrez vite 4 nouveaux menus à partager:\r\nl.dominos.fr/MqGKjT0Vi2\r\nConditions sur le site Domino's.\r\nSTOP : l.dominos.fr/oIv05Yymdm";
      final lf = crlf.replaceAll('\r\n', '\n');

      final crlfMessage = SegmentedMessage(crlf);
      expect(crlfMessage.lineBreakStyle, LineBreakStyle.crlf);
      expect(crlfMessage.numberOfCharacters, 162);
      expect(crlfMessage.segmentsCount, 2);

      final lfMessage = SegmentedMessage(lf);
      expect(lfMessage.lineBreakStyle, LineBreakStyle.lf);
      expect(lfMessage.numberOfCharacters, 159);
      expect(lfMessage.segmentsCount, 1);
    });
    test('Triple accents characters - Unicode test', () {
      final m = SegmentedMessage(_tripleAccent);
      expect(m.numberOfCharacters, 1);
      expect(m.numberOfUnicodeScalars, 4);
    });
    // Test for https://github.com/TwilioDevEd/message-segment-calculator/issues/17
    test('Triple accents characters - One Segment test', () {
      expect(SegmentedMessage('$_tripleAccent${'a' * 66}').segmentsCount, 1);
    });
    test('Triple accents characters - Two Segments test', () {
      expect(SegmentedMessage('$_tripleAccent${'a' * 67}').segmentsCount, 2);
    });
  });

  group('Test SegmentedMessage methods', () {
    test('getNonGsmCharacters()', () {
      expect(SegmentedMessage('más').getNonGsmCharacters(), ['á']);
    });
    test('getNonGsmCharacters() ignores spaces and line breaks', () {
      expect(SegmentedMessage('a b\nc\r\nd 😀').getNonGsmCharacters(), ['😀']);
    });
  });

  group('GSM-7 Segements analysis', () {
    final m = SegmentedMessage(_digits.substring(0, 307));
    test('Check User Data Header', () {
      for (var segmentIndex = 0; segmentIndex <= 2; segmentIndex++) {
        for (var index = 0; index < 6; index++) {
          expect(_elements(m, segmentIndex)[index], isA<UserDataHeader>());
        }
      }
    });
    test('Check last segment has only 1 character', () {
      expect(_elements(m, 2).length, 7);
      expect((_elements(m, 2)[6] as EncodedChar).raw, '7');
    });
  });

  group('UCS-2 Segements analysis', () {
    final m = SegmentedMessage(
        '😜2345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234');
    test('Check User Data Header', () {
      for (var segmentIndex = 0; segmentIndex <= 2; segmentIndex++) {
        for (var index = 0; index < 6; index++) {
          expect(_elements(m, segmentIndex)[index], isA<UserDataHeader>());
        }
      }
    });
    test('Check last segment has only 1 character', () {
      expect(_elements(m, 2).length, 7);
      expect((_elements(m, 2)[6] as EncodedChar).raw, '4');
    });
  });

  group('GSM characters in UCS-2 messages', () {
    test('GSM-7 char keeps its UTF-16 code unit in UCS-2', () {
      final m = SegmentedMessage('@😀');
      expect(m.encoding, SmsEncoding.ucs2);
      expect(m.encodedChars[0].raw, '@');
      expect(m.encodedChars[0].isGSM7, true);
      expect(m.encodedChars[0].codeUnits, [0x0040]); // UTF-16, not GSM septet
      expect(m.encodedChars[1].isGSM7, false);
    });
    test('GSM extension chars count as 1 unit each in UCS-2 mode (#57)', () {
      const message =
          '||||||||||||||||||||||||{||||||||||||||||||||||||||||∞||||||||||^|||||';
      final m = SegmentedMessage(message);
      expect(m.encoding, SmsEncoding.ucs2);
      expect(m.numberOfCharacters, 70);
      expect(m.segmentsCount, 1);
      final used = m.segments[0].elements
          .whereType<EncodedChar>()
          .fold<int>(0, (total, c) => total + c.codeUnits!.length);
      expect(used, 70);
      EncodedChar find(String raw) =>
          m.encodedChars.firstWhere((c) => c.raw == raw);
      expect(find('|').codeUnits, [0x007c]);
      expect(find('^').codeUnits, [0x005e]);
      expect(find('{').codeUnits, [0x007b]);
    });
    test('GSM extension chars use 2 code units in GSM-7 mode', () {
      final m = SegmentedMessage('{');
      expect(m.encodedChars[0].codeUnits, [0x1b, 0x28]);
      expect(m.numberOfCharacters, 2);
    });
  });

  group('Graphemes split like Twilio (grapheme-splitter, Unicode 10)', () {
    test('Pirate flag is 2 graphemes', () {
      final m = SegmentedMessage('🏴‍☠️');
      expect(m.graphemes, ['🏴‍', '☠️']);
      expect(m.numberOfCharacters, 2);
    });
    test('Rainbow flag, family and skin tones are 1 grapheme each', () {
      expect(SegmentedMessage('🏳️‍🌈').graphemes.length, 1);
      expect(SegmentedMessage('👨‍👩‍👧').graphemes.length, 1);
      expect(SegmentedMessage('👍🏽').graphemes.length, 1);
      expect(SegmentedMessage('🇮🇹🇺🇸').graphemes, ['🇮🇹', '🇺🇸']);
    });
  });

  group('countUtf8Bytes', () {
    test('empty string is 0 bytes', () => expect(countUtf8Bytes(''), 0));
    test('ASCII characters are 1 byte each',
        () => expect(countUtf8Bytes('Hello'), 5));
    test('2-byte characters (Latin accented)', () {
      expect(countUtf8Bytes('é'), 2);
      expect(countUtf8Bytes('ñ'), 2);
    });
    test('3-byte characters (CJK)', () {
      expect(countUtf8Bytes('中'), 3);
      expect(countUtf8Bytes('日'), 3);
    });
    test('4-byte characters (emoji)', () {
      expect(countUtf8Bytes('😀'), 4);
      expect(countUtf8Bytes('🌍'), 4);
    });
    test('mixed character widths', () => expect(countUtf8Bytes('Hé中😀'), 10));
    test('flag emoji (regional indicator pair)',
        () => expect(countUtf8Bytes('🇺🇸'), 8));
    test('ZWJ emoji sequence', () => expect(countUtf8Bytes('👨‍👩‍👧'), 18));
    test('newline characters', () {
      expect(countUtf8Bytes('\n'), 1);
      expect(countUtf8Bytes('\r\n'), 2);
      expect(countUtf8Bytes('\t'), 1);
    });
    test('null character is 1 byte', () => expect(countUtf8Bytes('\x00'), 1));
    test('boundary code points', () {
      expect(countUtf8Bytes('\u007F'), 1);
      expect(countUtf8Bytes('\u0080'), 2);
      expect(countUtf8Bytes('߿'), 2);
      expect(countUtf8Bytes('ࠀ'), 3);
      expect(countUtf8Bytes('￿'), 3);
    });
    test('long ASCII string byte count',
        () => expect(countUtf8Bytes('a' * 1600), 1600));
    test('long multi-byte string byte count',
        () => expect(countUtf8Bytes('中' * 400), 1200));
  });

  group('RCS US segmentation', () {
    test('empty message has 0 segments', () {
      final r = RcsSegmentedMessage('', RcsRegion.us);
      expect(r.segmentsCount, 0);
      expect(r.numberOfBytes, 0);
      expect(r.messageSize, 0);
      expect(r.segments, isEmpty);
      expect(r.messageType, RcsMessageType.rich);
    });
    test('single character is one Rich segment', () {
      final r = RcsSegmentedMessage('a', RcsRegion.us);
      expect(r.segmentsCount, 1);
      expect(r.messageType, RcsMessageType.rich);
      expect(r.numberOfBytes, 1);
    });
    test('160 UTF-8 bytes stays in one Rich segment', () {
      final r = RcsSegmentedMessage('a' * 160, RcsRegion.us);
      expect(r.segmentsCount, 1);
      expect(r.messageType, RcsMessageType.rich);
      expect(r.numberOfBytes, 160);
      expect(r.messageSize, 1280);
    });
    test('161 UTF-8 bytes splits into two Rich segments', () {
      final r = RcsSegmentedMessage('a' * 161, RcsRegion.us);
      expect(r.segmentsCount, 2);
      expect(r.segments[0].used, 160);
      expect(r.segments[1].used, 1);
    });
    test('320 bytes fills exactly two segments', () {
      final r = RcsSegmentedMessage('a' * 320, RcsRegion.us);
      expect(r.segmentsCount, 2);
      expect(r.segments[0].used, 160);
      expect(r.segments[1].used, 160);
    });
    test('321 bytes spills into third segment', () {
      final r = RcsSegmentedMessage('a' * 321, RcsRegion.us);
      expect(r.segmentsCount, 3);
      expect(r.segments[2].used, 1);
    });
    test('very long message (1000 bytes) segments correctly', () {
      final r = RcsSegmentedMessage('a' * 1000, RcsRegion.us);
      expect(r.segmentsCount, 7);
      expect(r.numberOfBytes, 1000);
      expect(r.segments[5].used, 160);
      expect(r.segments[6].used, 40);
    });
    test('all segments have capacity 160 and sequential indexes', () {
      final r = RcsSegmentedMessage('a' * 500, RcsRegion.us);
      expect(r.segmentsCount, 4);
      for (var i = 0; i < r.segments.length; i++) {
        expect(r.segments[i].capacity, 160);
        expect(r.segments[i].index, i);
      }
      expect(r.segments[3].used, 20);
    });
  });

  group('RCS International billing', () {
    test('empty message has 0 segments', () {
      final r = RcsSegmentedMessage('', RcsRegion.international);
      expect(r.segmentsCount, 0);
      expect(r.segments, isEmpty);
      expect(r.messageType, RcsMessageType.basic);
    });
    test('160 UTF-8 bytes is Basic', () {
      final r = RcsSegmentedMessage('a' * 160, RcsRegion.international);
      expect(r.segmentsCount, 1);
      expect(r.messageType, RcsMessageType.basic);
      expect(r.segments[0].capacity, 160);
      expect(r.segments[0].used, 160);
    });
    test('161 UTF-8 bytes is Single', () {
      final r = RcsSegmentedMessage('a' * 161, RcsRegion.international);
      expect(r.segmentsCount, 1);
      expect(r.messageType, RcsMessageType.single);
      expect(r.segments[0].capacity, 1600);
      expect(r.segments[0].used, 161);
    });
    test('International never segments regardless of length', () {
      final r = RcsSegmentedMessage('a' * 1000, RcsRegion.international);
      expect(r.segmentsCount, 1);
      expect(r.messageType, RcsMessageType.single);
      expect(r.segments, hasLength(1));
      expect(r.segments[0].capacity, 1600);
    });
    test('International with multi-byte characters uses tier capacity', () {
      final r = RcsSegmentedMessage('中' * 100, RcsRegion.international);
      expect(r.numberOfBytes, 300);
      expect(r.messageType, RcsMessageType.single);
      expect(r.segments[0].capacity, 1600);
      expect(r.segments[0].used, 300);
    });
    test('International Basic / Single threshold with multi-byte', () {
      expect(RcsSegmentedMessage('中' * 53, RcsRegion.international).messageType,
          RcsMessageType.basic);
      expect(RcsSegmentedMessage('中' * 54, RcsRegion.international).messageType,
          RcsMessageType.single);
    });
  });

  group('RCS sizes, encoding and edge cases', () {
    test('UTF-8 byte counting', () {
      expect(RcsSegmentedMessage('é').numberOfBytes, 2);
      expect(RcsSegmentedMessage('中').numberOfBytes, 3);
      expect(RcsSegmentedMessage('😄').numberOfBytes, 4);
      expect(RcsSegmentedMessage('😄').messageSize, 32);
      expect(RcsSegmentedMessage('Hi 😀!').numberOfBytes, 8);
    });
    test('multi-byte characters at segment boundary', () {
      final r = RcsSegmentedMessage('${'a' * 159}é', RcsRegion.us);
      expect(r.numberOfBytes, 161);
      expect(r.segmentsCount, 2);
    });
    test('defaults to US region', () {
      final r = RcsSegmentedMessage('test');
      expect(r.region, RcsRegion.us);
      expect(r.messageType, RcsMessageType.rich);
    });
    test('totalSize equals messageSize', () {
      final r = RcsSegmentedMessage('Hello World!', RcsRegion.us);
      expect(r.totalSize, r.messageSize);
    });
    test('always UTF-8', () {
      expect(RcsSegmentedMessage('abc').encodingName, 'UTF-8');
      expect(RcsSegmentedMessage('😀', RcsRegion.international).encodingName,
          'UTF-8');
    });
    test('whitespace, newlines and CRLF', () {
      expect(RcsSegmentedMessage('   ').numberOfBytes, 3);
      expect(RcsSegmentedMessage('\n\n\n').numberOfBytes, 3);
      expect(RcsSegmentedMessage('\r\n').numberOfBytes, 2);
    });
    test('message type labels match Twilio', () {
      expect(RcsMessageType.rich.label, 'Rich');
      expect(RcsMessageType.basic.label, 'Basic');
      expect(RcsMessageType.single.label, 'Single');
    });
  });
}
