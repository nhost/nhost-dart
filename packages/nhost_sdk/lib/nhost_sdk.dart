library nhost_sdk;

import 'package:http/http.dart' as http;
import 'package:nhost_sdk/src/logging.dart';

import 'src/auth.dart';
import 'src/auth_store.dart';
import 'src/session.dart';
import 'src/storage.dart';

export 'src/api/api_client.dart' show ApiException;
export 'src/api/auth_api_types.dart';
export 'src/api/storage_api_types.dart';
export 'src/auth.dart';
export 'src/auth_store.dart';
export 'src/logging.dart' show debugLogNhostErrorsToConsole;
export 'src/storage.dart';

/// API client for accessing Nhost's authentication and storage APIs.
///
/// User authentication and management is provided by the [auth] service, which
/// implements the Nhost Auth API: https://docs.nhost.io/storage/api-reference
///
/// File storage is provided by the [storage] service, which implements the
/// Nhost Storage API: https://docs.nhost.io/storage/api-reference
///
/// Additional packages for working with GraphQL and Flutter can be found at
/// https://pub.dev/publishers/nhost
class NhostClient {
  /// Constructs a new Nhost client.
  ///
  /// For information on getting started, please visit
  /// https://docs.nhost.io/libraries/nhost-dart-sdk#setup
  ///
  /// {@template nhost.api.NhostClient.baseUrl}
  /// [baseUrl] is the Nhost "Backend URL" that can be found on your Nhost
  /// project page.
  /// {@endtemplate}
  ///
  /// {@template nhost.api.NhostClient.authStore}
  /// [authStore] (optional) is used to persist authentication tokens
  /// between restarts of your app. If not provided, the tokens will not be
  /// persisted.
  /// {@endtemplate}
  ///
  /// {@template nhost.api.NhostClient.refreshToken}
  /// [refreshToken] (optional) is the result of a previously successful login,
  /// and is used to initialize this client into a logged-in state.
  /// {@endtemplate}
  ///
  /// {@template nhost.api.NhostClient.autoLogin}
  /// [autoLogin] (optional) indicates whether the client should attempt to
  /// login automatically using [refreshToken], or information pulled from
  /// the [authStore] (if available).
  /// {@endtemplate}
  ///
  /// {@template nhost.api.NhostClient.tokenRefreshInterval}
  /// [tokenRefreshInterval] (optional) is the amount of time the client will
  /// wait between refreshing its authentication tokens. If not provided, will
  /// default to a value provided by the server.
  /// {@endtemplate}
  ///
  /// {@template nhost.api.NhostClient.httpClientOverride}
  /// [httpClientOverride] (optional) can be provided in order to customize the
  /// requests made by the Nhost APIs, which can be useful for proxy
  /// configuration and debugging.
  /// {@endtemplate}
  NhostClient({
    required this.baseUrl,
    AuthStore? authStore,
    String? refreshToken,
    bool? autoLogin = true,
    Duration? tokenRefreshInterval,
    http.Client? httpClientOverride,
  })  : _session = UserSession(),
        _authStore = authStore ?? InMemoryAuthStore(),
        _refreshToken = refreshToken,
        _autoLogin = autoLogin ?? true,
        _refreshInterval = tokenRefreshInterval,
        _httpClient = httpClientOverride {
    initializeLogging();
  }

  /// The Nhost project's backend URL.
  final String baseUrl;

  /// Persists authentication information between restarts of the app.
  final AuthStore _authStore;
  final String? _refreshToken;
  final Duration? _refreshInterval;
  final UserSession _session;
  final bool _autoLogin;

  /// The HTTP client used by this client's services.
  http.Client get httpClient => _httpClient ??= http.Client();
  http.Client? _httpClient;

  /// The Nhost authentication service.
  Auth get auth => _auth ??= Auth(
        baseUrl: '$baseUrl/auth',
        authStore: _authStore,
        refreshToken: _refreshToken,
        autoLogin: _autoLogin,
        refreshInterval: _refreshInterval,
        session: _session,
        httpClient: httpClient,
      );
  Auth? _auth;

  /// The Nhost file storage service.
  Storage get storage => _storage ??= Storage(
        baseUrl: '$baseUrl/storage',
        httpClient: httpClient,
        session: _session,
      );
  Storage? _storage;

  /// Releases the resources used by this client.
  void close() {
    _auth?.close();
    _storage?.close();
    _httpClient?.close();
  }
}
