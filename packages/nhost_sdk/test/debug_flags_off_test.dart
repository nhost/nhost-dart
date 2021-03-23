import 'package:nhost_sdk/src/debug.dart';
import 'package:test/test.dart';

void main() {
  group('debug flags', () {
    test('debugPrintApiCalls is off', () {
      expect(debugPrintApiCalls, false);
    });
  });
}
