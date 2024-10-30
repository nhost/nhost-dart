import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:nhost_sdk/nhost_sdk.dart';

import '../nhost_graphql_adapter.dart';

/// Constructs a GQL client for accessing Nhost.io's backend.
///
/// The connection will be configured to automatically reflect the logged in
/// state of [nhostClient], and will change over time.
///
/// {@template nhost.graphqlClient.gqlCache}
/// [gqlCache] (optional) the GraphQL cache to provide to the client. Defaults
/// to a basic [GraphQLCache] instance.
/// {@endtemplate}
///
/// {@template nhost.graphqlClient.defaultHeaders}
/// [defaultHeaders] (optional) a map of headers that will accompany HTTP
/// requests and the initial web socket payload. Any matching headers set by the
/// client will overwrite the default values.
/// {@endtemplate}
///
/// {@template nhost.graphqlClient.httpClientOverride}
/// [httpClientOverride] (optional) can be provided in order to customize the
/// requests made by the Nhost APIs, which can be useful for proxy configuration
/// and debugging.
/// {@endtemplate}
///
/// {@template nhost.graphqlClient.defaultPolicies}
/// [defaultPolicies] (optional) customizes the default policies used by the
/// client. This can be used to change the cache-and-network or network-only
/// behavior of the client.
/// {@endtemplate}
///
/// {@template nhost.graphqlClient.alwaysRebroadcast}
/// [alwaysRebroadcast] (optional) if true, the client will rebroadcast watch
/// queries when the underlying cache changes. This is false by default.
/// {@endtemplate}
///
/// {@template nhost.graphqlClient.deepEquals}
/// [deepEquals] (optional) overrides the default deep equals comparison for
/// caching.
/// {@endtemplate}
///
/// {@template nhost.graphqlClient.deduplicatePollers}
/// [deduplicatePollers] (optional) if true, the client will deduplicate
/// duplicate pollers. This is true by default.
/// {@endtemplate}
///
/// {@template nhost.graphqlClient.queryRequestTimeout}
/// [queryRequestTimeout] (optional) overrides the default request timeout for
/// queries. This is 10 seconds by default.
/// {@endtemplate}
GraphQLClient createNhostGraphQLClient(
  NhostClientBase nhostClient, {
  GraphQLCache? gqlCache,
  Map<String, String>? defaultHeaders,
  http.Client? httpClientOverride,
  DefaultPolicies? defaultPolicies,
  bool? alwaysRebroadcast,
  DeepEqualsFn? deepEquals,
  bool? deduplicatePollers,
  Duration? queryRequestTimeout,
}) {
  return createNhostGraphQLClientForAuth(
    nhostClient.gqlEndpointUrl,
    nhostClient.auth,
    gqlCache: gqlCache,
    defaultHeaders: defaultHeaders,
    httpClientOverride: httpClientOverride,
    defaultPolicies: defaultPolicies,
    alwaysRebroadcast: alwaysRebroadcast,
    deepEquals: deepEquals,
    deduplicatePollers: deduplicatePollers,
    queryRequestTimeout: queryRequestTimeout,
  );
}

/// Constructs a GQL client for accessing Nhost.io's backend.
///
/// The connection will be configured to automatically reflect the logged in
/// state of [nhostAuth], and will change over time.
///
/// [nhostGqlEndpointUrl] can be found at [NhostClient.gqlEndpointUrl].
///
/// {@macro nhost.graphqlClient.gqlCache}
///
/// {@macro nhost.graphqlClient.defaultHeaders}
///
/// {@macro nhost.graphqlClient.httpClientOverride}
///
/// {@macro nhost.graphqlClient.defaultPolicies}
///
/// {@macro nhost.graphqlClient.alwaysRebroadcast}
///
/// {@macro nhost.graphqlClient.deepEquals}
///
/// {@macro nhost.graphqlClient.deduplicatePollers}
///
/// {@macro nhost.graphqlClient.queryRequestTimeout}
///
GraphQLClient createNhostGraphQLClientForAuth(
  String nhostGqlEndpointUrl,
  HasuraAuthClient nhostAuth, {
  GraphQLCache? gqlCache,
  Map<String, String>? defaultHeaders,
  http.Client? httpClientOverride,
  DefaultPolicies? defaultPolicies,
  bool? alwaysRebroadcast,
  DeepEqualsFn? deepEquals,
  bool? deduplicatePollers,
  Duration? queryRequestTimeout,
}) {
  return GraphQLClient(
    link: combinedLinkForNhostAuth(
      nhostGqlEndpointUrl,
      nhostAuth,
      defaultHeaders: defaultHeaders,
      httpClientOverride: httpClientOverride,
    ),
    cache: gqlCache ?? GraphQLCache(),
    defaultPolicies: defaultPolicies,
    alwaysRebroadcast: alwaysRebroadcast ?? false,
    deepEquals: deepEquals,
    deduplicatePollers: deduplicatePollers ?? false,
    queryRequestTimeout: queryRequestTimeout ?? const Duration(seconds: 5),
  );
}
