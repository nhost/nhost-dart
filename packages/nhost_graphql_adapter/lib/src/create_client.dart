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
/// [defaultPolicies] (optional) default fetch and error policies for queries,
/// mutations, and subscriptions.
/// {@endtemplate}
///
/// {@template nhost.graphqlClient.alwaysRebroadcast}
/// [alwaysRebroadcast] (optional) if true, always rebroadcasts changes to
/// listeners, even if data is unchanged.
/// {@endtemplate}
///
/// {@template nhost.graphqlClient.deepEquals}
/// [deepEquals] (optional) function to compare query results for deep equality.
/// {@endtemplate}
///
/// {@template nhost.graphqlClient.asyncDeepEquals}
/// [asyncDeepEquals] (optional) async function to compare query results for
/// deep equality.
/// {@endtemplate}
///
/// {@template nhost.graphqlClient.deduplicatePollers}
/// [deduplicatePollers] (optional) if true, deduplicates polling queries to
/// avoid duplicate requests.
/// {@endtemplate}
///
/// {@template nhost.graphqlClient.queryRequestTimeout}
/// [queryRequestTimeout] (optional) timeout duration for query requests.
/// Defaults to 1 minute.
/// {@endtemplate}
GraphQLClient createNhostGraphQLClient(
  NhostClientBase nhostClient, {
  GraphQLCache? gqlCache,
  Map<String, String>? defaultHeaders,
  http.Client? httpClientOverride,
  DefaultPolicies? defaultPolicies,
  bool alwaysRebroadcast = false,
  DeepEqualsFn? deepEquals,
  AsyncDeepEqualsFn? asyncDeepEquals,
  bool deduplicatePollers = false,
  Duration? queryRequestTimeout = const Duration(minutes: 1),
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
    asyncDeepEquals: asyncDeepEquals,
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
/// {@macro nhost.graphqlClient.asyncDeepEquals}
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
  bool alwaysRebroadcast = false,
  DeepEqualsFn? deepEquals,
  AsyncDeepEqualsFn? asyncDeepEquals,
  bool deduplicatePollers = false,
  Duration? queryRequestTimeout = const Duration(minutes: 1),
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
    alwaysRebroadcast: alwaysRebroadcast,
    deepEquals: deepEquals,
    asyncDeepEquals: asyncDeepEquals,
    deduplicatePollers: deduplicatePollers,
    queryRequestTimeout: queryRequestTimeout,
  );
}
