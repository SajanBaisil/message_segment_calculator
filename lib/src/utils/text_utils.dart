import 'dart:convert';

import 'grapheme_splitter.dart';

/// Splits [message] into graphemes (user-perceived characters), the same way
/// Twilio's calculator does.
///
/// A `\r\n` pair is a single grapheme in Unicode, but SMS counts it as two
/// characters, so it is split back into `\r` and `\n`.
List<String> splitGraphemes(String message) => splitGraphemesUnicode10(message)
    .expand((grapheme) => grapheme == '\r\n' ? grapheme.split('') : [grapheme])
    .toList(growable: false);

/// Number of bytes [message] takes when encoded as UTF-8.
///
/// Lone surrogates are encoded as U+FFFD (3 bytes), the same as the
/// JavaScript `TextEncoder`.
int countUtf8Bytes(String message) => utf8.encode(message).length;
