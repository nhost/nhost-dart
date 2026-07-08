import 'package:flutter_test/flutter_test.dart';
import 'package:nhost_flutter/nhost_flutter.dart';

/// Minimal in-memory [AuthStore] for tests — avoids a flutter_secure_storage
/// platform channel during unit tests.
class _MemoryAuthStore implements AuthStore {
  final _store = <String, String>{};
  @override
  Future<String?> getString(String key) async => _store[key];
  @override
  Future<void> setString(String key, String value) async => _store[key] = value;
  @override
  Future<void> removeItem(String key) async => _store.remove(key);
}

void main() {
  tearDown(() => Nhost.reset());

  group('Nhost singleton', () {
    test('initialize returns an NhostClient', () async {
      final client = await Nhost.initialize(
        subdomain: Subdomain(subdomain: 'test', region: 'us-east-1'),
        authStore: _MemoryAuthStore(),
        restoreSession: false,
      );
      expect(client, isA<NhostClient>());
    });

    test('instance returns the same client after initialize', () async {
      final client = await Nhost.initialize(
        subdomain: Subdomain(subdomain: 'test', region: 'us-east-1'),
        authStore: _MemoryAuthStore(),
        restoreSession: false,
      );
      expect(Nhost.instance, same(client));
    });

    test('calling initialize twice throws StateError', () async {
      await Nhost.initialize(
        subdomain: Subdomain(subdomain: 'test', region: 'us-east-1'),
        authStore: _MemoryAuthStore(),
        restoreSession: false,
      );
      expect(
        () => Nhost.initialize(
          subdomain: Subdomain(subdomain: 'test', region: 'us-east-1'),
          authStore: _MemoryAuthStore(),
          restoreSession: false,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('accessing instance before initialize throws StateError', () {
      expect(() => Nhost.instance, throwsA(isA<StateError>()));
    });

    test('reset clears the singleton', () async {
      await Nhost.initialize(
        subdomain: Subdomain(subdomain: 'test', region: 'us-east-1'),
        authStore: _MemoryAuthStore(),
        restoreSession: false,
      );
      Nhost.reset();
      expect(() => Nhost.instance, throwsA(isA<StateError>()));
    });

    test('local() uses localhost service URLs', () async {
      final client = await Nhost.local(
        authStore: _MemoryAuthStore(),
        restoreSession: false,
      );
      expect(client.serviceUrls?.authUrl, contains('localhost:1337'));
    });
  });
}
