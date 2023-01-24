import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:nhost_gql_links/nhost_gql_links.dart';
import 'package:nhost_dart/nhost_dart.dart';

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
GraphQLClient createNhostGraphQLClient(
  NhostClient nhostClient, {
  GraphQLCache? gqlCache,
  Map<String, String>? defaultHeaders,
  http.Client? httpClientOverride,
}) {
  return createNhostGraphQLClientForAuth(
    nhostClient.gqlEndpointUrl,
    nhostClient.auth,
    gqlCache: gqlCache,
    defaultHeaders: defaultHeaders,
    httpClientOverride: httpClientOverride,
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
GraphQLClient createNhostGraphQLClientForAuth(
  String nhostGqlEndpointUrl,
  AuthClient nhostAuth, {
  GraphQLCache? gqlCache,
  Map<String, String>? defaultHeaders,
  http.Client? httpClientOverride,
}) {
  return GraphQLClient(
    link: combinedLinkForNhostAuth(
      nhostGqlEndpointUrl,
      nhostAuth,
      defaultHeaders: defaultHeaders,
      httpClientOverride: httpClientOverride,
    ),
    cache: gqlCache ?? GraphQLCache(),
  );
}
