library nhost_dart_sdk;

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'src/auth.dart';
import 'src/client_storage.dart';
import 'src/session.dart';
import 'src/storage.dart';

export 'src/api/api_client.dart' show ApiException;
export 'src/api/auth_api_types.dart';
export 'src/api/storage_api_types.dart';
export 'src/auth.dart';
export 'src/client_storage.dart';
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
///
/// TODO(shyndman): We need to create an nhost publisher
class NhostClient {
  /// Constructs a new Nhost client.
  ///
  /// For information on getting started, please visit
  /// https://docs.nhost.io/libraries/nhost-dart-sdk#setup
  NhostClient({
    @required this.baseUrl,
    ClientStorage clientStorage,
    Duration tokenRefreshInterval,
  })  : assert(
            baseUrl != null,
            'Please specify a baseURL. More information at '
            // TODO(shyndman): URL for Dart required
            'https://docs.nhost.io/libraries/nhost-dart-sdk#setup'),
        _session = UserSession(),
        _refreshInterval = tokenRefreshInterval,
        clientStorage = clientStorage ?? InMemoryClientStorage();

  /// The Nhost project's backend URL.
  final String baseUrl;

  /// Persists authentication information between restarts of the process.
  final ClientStorage clientStorage;
  final Duration _refreshInterval;
  final UserSession _session;

  /// The HTTP client used by this client's services.
  @nonVirtual
  http.Client get httpClient => _httpClient ??= createHttpClient();
  http.Client _httpClient;

  /// Creates the [HttpClient] to be used by this client's APIs.
  ///
  /// Can be overridden by subclasses. Useful for introducing custom clients for
  /// proxies, or debugging.
  @protected
  http.Client createHttpClient() => http.Client();

  /// The Nhost authentication service.
  Auth get auth => _auth ??= Auth(
        baseUrl: '$baseUrl/auth',
        httpClient: httpClient,
        clientStorage: clientStorage,
        refreshInterval: _refreshInterval,
        session: _session,
      );
  Auth _auth;

  /// The Nhost file storage service.
  Storage get storage => _storage ??= Storage(
        baseUrl: '$baseUrl/storage',
        httpClient: httpClient,
        session: _session,
      );
  Storage _storage;

  /// Releases the resources used by this client.
  void close() {
    _auth?.close();
    _storage?.close();
    _httpClient?.close();
  }
}
