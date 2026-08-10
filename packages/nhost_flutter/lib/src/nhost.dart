import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nhost_dart/nhost_dart.dart';

import 'secure_auth_store.dart';

/// Entry point for the Nhost Flutter SDK.
///
/// Call [initialize] once in `main()` before [runApp], then access the client
/// anywhere via [instance].
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Nhost.initialize(
///     subdomain: Subdomain(subdomain: 'xxx', region: 'eu-central-1'),
///   );
///   runApp(const MyApp());
/// }
/// ```
class Nhost {
  Nhost._();

  static NhostClient? _instance;

  /// Initializes the Nhost SDK and returns the configured [NhostClient].
  ///
  /// Exactly one of [subdomain] or [serviceUrls] must be provided.
  ///
  /// Tokens are persisted via [SecureAuthStore] by default. Pass [authStore]
  /// to override. Pass `restoreSession: false` to skip the automatic restore.
  ///
  /// Throws [StateError] if called more than once without [reset].
  static Future<NhostClient> initialize({
    Subdomain? subdomain,
    ServiceUrls? serviceUrls,
    AuthStore? authStore,
    Duration? tokenRefreshInterval,
    http.Client? httpClientOverride,
    bool restoreSession = true,
  }) async {
    if (_instance != null) {
      throw StateError(
        'Nhost is already initialized. Call Nhost.reset() first.',
      );
    }

    _instance = NhostClient(
      subdomain: subdomain,
      serviceUrls: serviceUrls,
      authStore: authStore ?? const SecureAuthStore(),
      tokenRefreshInterval: tokenRefreshInterval,
      httpClientOverride: httpClientOverride,
    );

    if (restoreSession) {
      await _instance!.auth
          .signInWithStoredCredentials()
          .catchError((_) => AuthResponse(session: null));
    }

    return _instance!;
  }

  /// Convenience initializer for local Nhost development.
  ///
  /// Defaults to `http://localhost:1337` — the standard `nhost dev` port.
  /// On Android emulators pass `authUrl: 'http://10.0.2.2:1337/v1/auth'` etc.
  static Future<NhostClient> local({
    String authUrl = 'http://localhost:1337/v1/auth',
    String storageUrl = 'http://localhost:1337/v1/storage',
    String functionsUrl = 'http://localhost:1337/v1/functions',
    String graphqlUrl = 'http://localhost:1337/v1/graphql',
    AuthStore? authStore,
    http.Client? httpClientOverride,
    bool restoreSession = true,
  }) =>
      initialize(
        serviceUrls: ServiceUrls(
          authUrl: authUrl,
          storageUrl: storageUrl,
          functionsUrl: functionsUrl,
          graphqlUrl: graphqlUrl,
        ),
        authStore: authStore,
        httpClientOverride: httpClientOverride,
        restoreSession: restoreSession,
      );

  /// The initialized [NhostClient].
  ///
  /// Throws [StateError] if accessed before [initialize] is called.
  static NhostClient get instance {
    final inst = _instance;
    if (inst == null) {
      throw StateError(
        'Nhost has not been initialized. Call Nhost.initialize() first.',
      );
    }
    return inst;
  }

  /// Clears the singleton. Intended for use in tests only.
  @visibleForTesting
  static void reset() {
    _instance?.close();
    _instance = null;
  }
}
