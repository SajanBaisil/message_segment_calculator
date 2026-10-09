// Dart port of grapheme-splitter 1.0.4
// (https://github.com/orling/grapheme-splitter), the grapheme splitter used by
// Twilio's message segment calculator.
//
// Twilio's calculator never splits a grapheme across two segments and counts
// UCS-2 characters as graphemes, so its results depend on where this exact
// splitter puts the boundaries. It implements Unicode 10.0.0 rules, which
// differ from current Unicode (and so from `package:characters`) for newer
// emoji sequences such as 🏴‍☠️ or 🫱🏼‍🫲🏿. The logic below follows the
// JavaScript source line for line, quirks included, so both calculators
// always agree.
//
// grapheme-splitter: Copyright (c) 2015 Orlin Georgiev, MIT License.

part 'grapheme_break_property.dart';

// Grapheme break properties.
const int _cr = 0;
const int _lf = 1;
const int _control = 2;
const int _extend = 3;
const int _regionalIndicator = 4;
const int _spacingMark = 5;
const int _l = 6;
const int _v = 7;
const int _t = 8;
const int _lv = 9;
const int _lvt = 10;
const int _other = 11;
const int _prepend = 12;
const int _eBase = 13;
const int _eModifier = 14;
const int _zwj = 15;
const int _glueAfterZwj = 16;
const int _eBaseGaz = 17;

// Break types.
const int _notBreak = 0;
const int _breakStart = 1;
const int _break = 2;
const int _breakLastRegional = 3;
const int _breakPenultimateRegional = 4;

/// Splits [str] into grapheme clusters, exactly like grapheme-splitter's
/// `splitGraphemes()`.
List<String> splitGraphemesUnicode10(String str) {
  final res = <String>[];
  var index = 0;
  int brk;
  while ((brk = _nextBreak(str, index)) < str.length) {
    res.add(str.substring(index, brk));
    index = brk;
  }
  if (index < str.length) {
    res.add(str.substring(index));
  }
  return res;
}

bool _isSurrogate(String str, int pos) {
  if (pos < 0 || pos + 1 >= str.length) return false;
  final hi = str.codeUnitAt(pos);
  final low = str.codeUnitAt(pos + 1);
  return 0xD800 <= hi && hi <= 0xDBFF && 0xDC00 <= low && low <= 0xDFFF;
}

/// Gets a Unicode code point from a UTF-16 string, handling surrogate pairs.
int _codePointAt(String str, int idx) {
  final code = str.codeUnitAt(idx);

  // if a high surrogate
  if (0xD800 <= code && code <= 0xDBFF && idx < str.length - 1) {
    final hi = code;
    final low = str.codeUnitAt(idx + 1);
    if (0xDC00 <= low && low <= 0xDFFF) {
      return ((hi - 0xD800) * 0x400) + (low - 0xDC00) + 0x10000;
    }
    return hi;
  }

  // if a low surrogate
  if (0xDC00 <= code && code <= 0xDFFF && idx >= 1) {
    final hi = str.codeUnitAt(idx - 1);
    final low = code;
    if (0xD800 <= hi && hi <= 0xDBFF) {
      return ((hi - 0xD800) * 0x400) + (low - 0xDC00) + 0x10000;
    }
    return low;
  }

  // just return the char if an unmatched surrogate half or a
  // single-char codepoint
  return code;
}

/// JavaScript `Array.prototype.slice` semantics (negative and out of range
/// indexes are clamped instead of throwing).
List<int> _slice(List<int> list, int start, [int? end]) {
  int clamp(int i) {
    if (i < 0) i += list.length;
    if (i < 0) return 0;
    return i > list.length ? list.length : i;
  }

  final from = clamp(start);
  final to = clamp(end ?? list.length);
  return from < to ? list.sublist(from, to) : const [];
}

/// Returns whether a break is allowed between the two given grapheme
/// breaking classes.
int _shouldBreak(int start, List<int> mid, int end) {
  final all = [start, ...mid, end];
  final previous = all[all.length - 2];
  final next = end;

  // Lookahead termintor for:
  // GB10. (E_Base | EBG) Extend* ?	E_Modifier
  final eModifierIndex = all.lastIndexOf(_eModifier);
  if (eModifierIndex > 1 &&
      _slice(all, 1, eModifierIndex).every((c) => c == _extend) &&
      ![_extend, _eBase, _eBaseGaz].contains(start)) {
    return _break;
  }

  // Lookahead termintor for:
  // GB12. ^ (RI RI)* RI	?	RI
  // GB13. [^RI] (RI RI)* RI	?	RI
  final rIIndex = all.lastIndexOf(_regionalIndicator);
  if (rIIndex > 0 &&
      _slice(all, 1, rIIndex).every((c) => c == _regionalIndicator) &&
      ![_prepend, _regionalIndicator].contains(previous)) {
    if (all.where((c) => c == _regionalIndicator).length % 2 == 1) {
      return _breakLastRegional;
    } else {
      return _breakPenultimateRegional;
    }
  }

  // GB3. CR X LF
  if (previous == _cr && next == _lf) {
    return _notBreak;
  }
  // GB4. (Control|CR|LF) ÷
  else if (previous == _control || previous == _cr || previous == _lf) {
    if (next == _eModifier && mid.every((c) => c == _extend)) {
      return _break;
    } else {
      return _breakStart;
    }
  }
  // GB5. ÷ (Control|CR|LF)
  else if (next == _control || next == _cr || next == _lf) {
    return _breakStart;
  }
  // GB6. L X (L|V|LV|LVT)
  else if (previous == _l &&
      (next == _l || next == _v || next == _lv || next == _lvt)) {
    return _notBreak;
  }
  // GB7. (LV|V) X (V|T)
  else if ((previous == _lv || previous == _v) && (next == _v || next == _t)) {
    return _notBreak;
  }
  // GB8. (LVT|T) X (T)
  else if ((previous == _lvt || previous == _t) && next == _t) {
    return _notBreak;
  }
  // GB9. X (Extend|ZWJ)
  else if (next == _extend || next == _zwj) {
    return _notBreak;
  }
  // GB9a. X SpacingMark
  else if (next == _spacingMark) {
    return _notBreak;
  }
  // GB9b. Prepend X
  else if (previous == _prepend) {
    return _notBreak;
  }

  // GB10. (E_Base | EBG) Extend* ?	E_Modifier
  final previousNonExtendIndex =
      all.contains(_extend) ? all.lastIndexOf(_extend) - 1 : all.length - 2;
  // `all[-1]` is `undefined` in JavaScript, which matches neither class.
  if (previousNonExtendIndex >= 0 &&
      [_eBase, _eBaseGaz].contains(all[previousNonExtendIndex]) &&
      _slice(all, previousNonExtendIndex + 1, -1).every((c) => c == _extend) &&
      next == _eModifier) {
    return _notBreak;
  }

  // GB11. ZWJ ? (Glue_After_Zwj | EBG)
  if (previous == _zwj && [_glueAfterZwj, _eBaseGaz].contains(next)) {
    return _notBreak;
  }

  // GB12. ^ (RI RI)* RI ? RI
  // GB13. [^RI] (RI RI)* RI ? RI
  if (mid.contains(_regionalIndicator)) {
    return _break;
  }
  if (previous == _regionalIndicator && next == _regionalIndicator) {
    return _notBreak;
  }

  // GB999. Any ? Any
  return _breakStart;
}

/// Returns the next grapheme break in the string after the given index.
int _nextBreak(String string, int index) {
  if (index < 0) {
    return 0;
  }
  if (index >= string.length - 1) {
    return string.length;
  }
  final prev = _graphemeBreakProperty(_codePointAt(string, index));
  final mid = <int>[];
  for (var i = index + 1; i < string.length; i++) {
    // check for already processed low surrogates
    if (_isSurrogate(string, i - 1)) {
      continue;
    }

    final next = _graphemeBreakProperty(_codePointAt(string, i));
    // Every break type except "not break" is a break, as in JavaScript where
    // only 0 is falsy.
    if (_shouldBreak(prev, mid, next) != _notBreak) {
      return i;
    }

    mid.add(next);
  }
  return string.length;
}

/// Grapheme break property of [code], looked up in [_graphemeBreakRanges].
int _graphemeBreakProperty(int code) {
  var low = 0;
  var high = _graphemeBreakRanges.length ~/ 3 - 1;
  while (low <= high) {
    final mid = (low + high) >> 1;
    final start = _graphemeBreakRanges[mid * 3];
    final end = _graphemeBreakRanges[mid * 3 + 1];
    if (code < start) {
      high = mid - 1;
    } else if (code > end) {
      low = mid + 1;
    } else {
      return _graphemeBreakRanges[mid * 3 + 2];
    }
  }
  return _other;
}
