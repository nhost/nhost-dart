library nhost_dart_sdk;

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

  Auth get auth => _auth ??= Auth(
        baseUrl: '$baseUrl/auth',
        autoLogin: _autoLogin,
        clientStorage: clientStorage,
        refreshInterval: _refreshInterval,
        session: _session,
      );
  Auth _auth;

  Storage get storage => _storage ??= Storage(
        baseUrl: '$baseUrl/storage',
        session: _session,
      );
  Storage _storage;
}
