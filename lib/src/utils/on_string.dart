/// Extension on nullable [String] providing convenience null/empty checks and formatting.
extension CustomStringExt on String? {
  /// Returns `true` if this string is `null` or empty (after trimming whitespace).
  bool get isNullOrEmpty => this == null || (this ?? '').trim().isEmpty;

  /// Returns `true` if this string is not `null`, not empty, and not the literal string `'null'`.
  bool get notNullNorEmpty =>
      this != null &&
      (this ?? '').trim().isNotEmpty &&
      (this ?? '').trim() != 'null';

  /// Capitalizes the first letter of each word in the string.
  String get firstLetterToCap {
    if (isNullOrEmpty) return '';

    final temp = <String>[];
    this!.trim().split(' ').toList().forEach((element) {
      if (element.trim().isEmpty) return;
      temp.add(element[0].toUpperCase() + element.substring(1));
    });
    return temp.join(' ');
  }
}
