library nhost_dart;

import 'package:http/http.dart' as http;
import 'package:nhost_functions_dart/nhost_functions_dart.dart';
import 'package:nhost_sdk/nhost_sdk.dart';
import 'package:nhost_auth_dart/nhost_auth_dart.dart';
import 'package:nhost_storage_dart/nhost_storage_dart.dart';

import 'src/logging.dart';

export 'package:nhost_sdk/nhost_sdk.dart'
    show
        ApiException,
        Session,
        createNhostServiceEndpoint,
        ServiceUrls,
        Subdomain,
        AuthenticationState,
        AuthStateChangedCallback,
        UnsubscribeDelegate,
        AuthStore;
export 'package:nhost_storage_dart/nhost_storage_dart.dart'
    show NhostStorageClient, ImageCornerRadius, ImageTransform;
export 'package:nhost_auth_dart/nhost_auth_dart.dart' show NhostAuthClient;
export 'package:nhost_functions_dart/nhost_functions_dart.dart'
    show NhostFunctionsClient;
export 'src/logging.dart' show debugLogNhostErrorsToConsole;
export 'package:nhost_graphql_adapter/nhost_graphql_adapter.dart'
    show
        createNhostGraphQLClientForAuth,
        combinedLinkForNhost,
        createNhostGraphQLClient;

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
class NhostClient implements NhostClientBase {
  /// Constructs a new Nhost client.
  ///
  /// {@template nhost.api.NhostClient.subdomain}
  /// [subdomain] is the Nhost "subdomain" and "region" that can be found on your Nhost
  /// project page.
  /// for local development pass 'localhost' or 'localhost:1337' to subdomain
  /// and leave region empty string '';
  /// {@endtemplate}
  ///
  /// {@template nhost.api.NhostClient.serviceUrls}
  /// [region] is the Nhost services Urls that can be found on
  /// your Nhost self-hosted project page.
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
    this.subdomain,
    this.serviceUrls,
    AuthStore? authStore,
    Duration? tokenRefreshInterval,
    http.Client? httpClientOverride,
  })  : _session = UserSession(),
        _authStore = authStore ?? InMemoryAuthStore(),
        _refreshInterval = tokenRefreshInterval,
        _httpClient = httpClientOverride {
    if ((subdomain == null && serviceUrls == null) ||
        (subdomain != null && serviceUrls != null)) {
      throw ArgumentError.notNull(
        'You have to pass either [Subdomain] or [ServiceUrls]',
      );
    }
    initializeLogging();
  }

  /// The Nhost project's backend subdomain and region
  @override
  final Subdomain? subdomain;

  /// The Nhost project's backend region
  @override
  final ServiceUrls? serviceUrls;

  /// Persists authentication information between restarts of the app.
  final AuthStore _authStore;
  final Duration? _refreshInterval;
  final UserSession _session;

  /// The HTTP client used by this client's services.
  @override
  http.Client get httpClient => _httpClient ??= http.Client();
  http.Client? _httpClient;

  /// The GraphQL endpoint URL.
  @override
  String get gqlEndpointUrl {
    if (subdomain != null) {
      return createNhostServiceEndpoint(
        subdomain: subdomain!.subdomain,
        region: subdomain!.region,
        service: 'graphql',
      );
    }

    return serviceUrls!.graphqlUrl;
  }

  /// The Nhost authentication service.
  ///
  /// https://docs.nhost.io/platform/authentication
  @override
  NhostAuthClient get auth => _auth ??= NhostAuthClient(
        url: subdomain != null
            ? createNhostServiceEndpoint(
                subdomain: subdomain!.subdomain,
                region: subdomain!.region,
                service: 'auth',
              )
            : serviceUrls!.authUrl,
        authStore: _authStore,
        tokenRefreshInterval: _refreshInterval,
        session: _session,
        httpClient: httpClient,
      );
  NhostAuthClient? _auth;

  /// The Nhost serverless functions service.
  ///
  /// https://docs.nhost.io/platform/serverless-functions
  @override
  NhostFunctionsClient get functions => _functions ??= NhostFunctionsClient(
        url: subdomain != null
            ? createNhostServiceEndpoint(
                subdomain: subdomain!.subdomain,
                region: subdomain!.region,
                service: 'functions',
              )
            : serviceUrls!.functionsUrl,
        session: _session,
        httpClient: httpClient,
      );
  NhostFunctionsClient? _functions;

  /// The Nhost file storage service.
  ///
  /// https://docs.nhost.io/platform/storage
  @override
  NhostStorageClient get storage => _storage ??= NhostStorageClient(
        url: subdomain != null
            ? createNhostServiceEndpoint(
                subdomain: subdomain!.subdomain,
                region: subdomain!.region,
                service: 'storage',
              )
            : serviceUrls!.storageUrl,
        httpClient: httpClient,
        session: _session,
      );
  NhostStorageClient? _storage;

  /// Releases the resources used by this client.
  @override
  void close() {
    _auth?.close();
    _storage?.close();
    _httpClient?.close();
  }
}
