library nhost_dart_sdk;

import 'dart:io';

import 'package:meta/meta.dart';

import 'src/auth.dart';
import 'src/client_storage.dart';
import 'src/session.dart';
import 'src/storage.dart';

export 'src/api/auth_api.dart';
export 'src/api/storage_api.dart';

class NhostClient {
  NhostClient({
    @required this.baseUrl,
    bool autoLogin = true,
    ClientStorage clientStorage,
    Duration tokenRefreshInterval,
  })  : assert(
            baseUrl != null,
            'Please specify a baseURL. More information at '
            // TODO(shyndman): URL for Dart required
            'https://docs.nhost.io/libraries/nhost-dart-sdk#setup'),
        _autoLogin = autoLogin,
        _session = UserSession(),
        _refreshInterval = tokenRefreshInterval,
        clientStorage = clientStorage ?? InMemoryClientStorage();

  final String baseUrl;
  final ClientStorage clientStorage;
  final Duration _refreshInterval;
  final bool _autoLogin;
  final UserSession _session;

  @nonVirtual
  HttpClient get httpClient => _httpClient ??= createHttpClient();
  HttpClient _httpClient;

  /// Creates the [HttpClient] to be used by this client's APIs.
  ///
  /// Can be overridden by subclasses. Useful for introducing custom clients for
  /// proxies, or debugging.
  @protected
  HttpClient createHttpClient() => HttpClient();

  Auth get auth => _auth ??= Auth(
        baseUrl: '$baseUrl/auth',
        httpClient: httpClient,
        autoLogin: _autoLogin,
        clientStorage: clientStorage,
        refreshInterval: _refreshInterval,
        session: _session,
      );
  Auth _auth;

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
