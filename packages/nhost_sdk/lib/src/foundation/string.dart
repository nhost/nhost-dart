extension StringExt on String {
  /// `true` if this string is `null` or the empty string
  bool get isNullOrEmpty => this == null || isEmpty;
}
