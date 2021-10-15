import 'package:test_api/expect.dart';

/// Matches when the provided iterable is monotonically increasing.
const isIncreasing = _IsIncreasingMatcher();

class _IsIncreasingMatcher extends Matcher {
  const _IsIncreasingMatcher();

  @override
  Description describe(Description description) =>
      description.add('is increasing');

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! Iterable) {
      return false;
    }

    final list = item.toList();
    for (final pair in _consecutivePairs(list)) {
      if (pair[0] > pair[1]) {
        return false;
      }
    }

    return true;
  }
}

Iterable<List<T>> _consecutivePairs<T>(List<T> elements) sync* {
  for (int i = 1; i < elements.length; i++) {
    yield [elements[i - 1], elements[i]];
  }
}
