import 'package:flutter_test/flutter_test.dart';
import 'package:nhost_flutter/nhost_flutter.dart';

void main() {
  group('SecureAuthStore', () {
    test('implements AuthStore', () {
      const AuthStore store = SecureAuthStore();
      expect(store, isA<SecureAuthStore>());
    });

    test('default instance is const-constructible', () {
      const a = SecureAuthStore();
      const b = SecureAuthStore();
      expect(identical(a, b), isTrue);
    });
  });
}
