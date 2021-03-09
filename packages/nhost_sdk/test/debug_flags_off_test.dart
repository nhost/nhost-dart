import 'package:nhost_dart_sdk/src/debug.dart';
import 'package:test/test.dart';

void main() {
  group('debug flags', () {
    test('debugPrintApiCalls is off', () {
      expect(debugPrintApiCalls, false);
    });
  });
}
