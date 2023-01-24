library nhost_dart;

import 'package:http/http.dart' as http;
import 'package:nhost_functions_dart/nhost_functions_dart.dart';
import 'package:nhost_sdk/nhost_sdk.dart';
import 'package:nhost_storage_dart/nhost_storage_dart.dart';
import 'package:nhost_auth_dart/nhost_auth_dart.dart';

import 'src/logging.dart';

export 'package:nhost_sdk/nhost_sdk.dart'
    show ApiException, Session, createNhostServiceEndpoint;
export 'package:nhost_storage_dart/nhost_storage_dart.dart'
    show StorageClient, ImageCornerRadius, ImageTransform;
export 'package:nhost_auth_dart/nhost_auth_dart.dart'
    show
        AuthClient,
        UnsubscribeDelegate,
        AuthenticationState,
        AuthStore,
        AuthStateChangedCallback;
export 'package:nhost_functions_dart/nhost_functions_dart.dart'
    show FunctionsClient;
export 'src/logging.dart' show debugLogNhostErrorsToConsole;

/// API client for accessing Nhost's authentication and storage APIs.
///
/// User authentication and management is provided by the [auth] service, which
/// implements the Nhost Authentication API.
///
/// File storage is provided by the [storage] service, which implements the
/// Nhost Storage API.
///
/// Additional packages for working with GraphQL and Flutter can be found at
/// https://pub.dev/publishers/nhost.io
class NhostClient {
  /// Constructs a new Nhost client.
  ///
  /// {@template nhost.api.NhostClient.subdomain}
  /// [subdomain] is the Nhost "subdomain" that can be found on your Nhost
  /// project page. for local development pass 'localhost' or 'localhost:1337'
  /// {@endtemplate}
  ///
  /// {@template nhost.api.NhostClient.region}
  /// [region] is the Nhost "region" that can be found on your Nhost
  /// project page. for local development pass empty string ''
  /// {@endtemplate}
  ///
  /// {@template nhost.api.NhostClient.authStore}
  /// [authStore] (optional) is used to persist authentication tokens
  /// between restarts of your app. If not provided, the tokens will not be
  /// persisted.
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
    required this.subdomain,
    required this.region,
    AuthStore? authStore,
    Duration? tokenRefreshInterval,
    http.Client? httpClientOverride,
  })  : _session = UserSession(),
        _authStore = authStore ?? InMemoryAuthStore(),
        _refreshInterval = tokenRefreshInterval,
        _httpClient = httpClientOverride {
    initializeLogging();
  }

  /// The Nhost project's backend subdomain
  final String subdomain;

  /// The Nhost project's backend region
  final String region;

  /// Persists authentication information between restarts of the app.
  final AuthStore _authStore;
  final Duration? _refreshInterval;
  final UserSession _session;

  /// The HTTP client used by this client's services.
  http.Client get httpClient => _httpClient ??= http.Client();
  http.Client? _httpClient;

  /// The GraphQL endpoint URL.
  String get gqlEndpointUrl => createNhostServiceEndpoint(
        subdomain: subdomain,
        region: region,
        service: 'graphql',
      );

  /// The Nhost authentication service.
  ///
  /// https://docs.nhost.io/platform/authentication
  AuthClient get auth => _auth ??= AuthClient(
        subdomain: subdomain,
        region: region,
        authStore: _authStore,
        tokenRefreshInterval: _refreshInterval,
        session: _session,
        httpClient: httpClient,
      );
  AuthClient? _auth;

  /// The Nhost serverless functions service.
  ///
  /// https://docs.nhost.io/platform/serverless-functions
  FunctionsClient get functions => _functions ??= FunctionsClient(
        subdomain: subdomain,
        region: region,
        session: _session,
        httpClient: httpClient,
      );
  FunctionsClient? _functions;

  /// The Nhost file storage service.
  ///
  /// https://docs.nhost.io/platform/storage
  StorageClient get storage => _storage ??= StorageClient(
        subdomain: subdomain,
        region: region,
        httpClient: httpClient,
        session: _session,
      );
  StorageClient? _storage;

  /// Releases the resources used by this client.
  void close() {
    _auth?.close();
    _storage?.close();
    _httpClient?.close();
  }
}
