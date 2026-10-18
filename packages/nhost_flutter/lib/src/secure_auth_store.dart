import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nhost_sdk/nhost_sdk.dart';

/// An [AuthStore] backed by `flutter_secure_storage`.
///
/// Used by default in [Nhost.initialize]. Swap it out by passing a custom
/// [AuthStore] to the `authStore` parameter.
///
/// Secure defaults:
/// - Android: `encryptedSharedPreferences: true`
/// - iOS: `KeychainAccessibility.first_unlock`
class SecureAuthStore implements AuthStore {
  const SecureAuthStore({
    this.androidOptions = const AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    this.iOSOptions = const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  });

  final AndroidOptions androidOptions;
  final IOSOptions iOSOptions;

  FlutterSecureStorage get _storage => FlutterSecureStorage(
        aOptions: androidOptions,
        iOptions: iOSOptions,
      );

  @override
  Future<String?> getString(String key) => _storage.read(key: key);

  @override
  Future<void> setString(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> removeItem(String key) => _storage.delete(key: key);
}
