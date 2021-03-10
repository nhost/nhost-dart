library nhost_dart_sdk;

import 'dart:io';

import 'package:meta/meta.dart';

import 'src/auth.dart';
import 'src/client_storage.dart';
import 'src/session.dart';
import 'src/storage.dart';

export 'src/api/api_client.dart' show ApiException;
export 'src/api/auth_api_types.dart';
export 'src/api/storage_api_types.dart';
export 'src/auth.dart';
export 'src/storage.dart';

class NhostClient {
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

  /// The Nhost backend URL
  final String baseUrl;

  /// Persists authentication information between restarts of the process.
  final ClientStorage clientStorage;
  final Duration _refreshInterval;
  final UserSession _session;

  /// The HTTP client used by this client's services.
  @nonVirtual
  HttpClient get httpClient => _httpClient ??= createHttpClient();
  HttpClient _httpClient;

  /// Creates the [HttpClient] to be used by this client's APIs.
  ///
  /// Can be overridden by subclasses. Useful for introducing custom clients for
  /// proxies, or debugging.
  @protected
  HttpClient createHttpClient() => HttpClient();

  /// This client's authentication service.
  Auth get auth => _auth ??= Auth(
        baseUrl: '$baseUrl/auth',
        httpClient: httpClient,
        clientStorage: clientStorage,
        refreshInterval: _refreshInterval,
        session: _session,
      );
  Auth _auth;

  /// This client's file storage service.
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
