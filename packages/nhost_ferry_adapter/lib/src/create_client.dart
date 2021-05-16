import 'package:ferry/ferry.dart' as ferry;
import 'package:http/http.dart' as http;
import 'package:nhost_gql_links/nhost_gql_links.dart';
import 'package:nhost_sdk/nhost_sdk.dart';

/// Constructs a Ferry GQL client for accessing Nhost.io's backend.
///
/// The connection will be configured to automatically reflect the logged in
/// state of [nhostClient], and will change over time.
///
/// {@template nhost.graphqlClient.gqlCache}
/// [gqlCache] (optional) the GraphQL cache to provide to the client. Defaults
/// to a basic [ferry.Cache] instance.
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
ferry.Client createNhostFerryClient(
  String nhostGqlEndpointUrl,
  NhostClient nhostClient, {
  ferry.Cache? gqlCache,
  Map<String, String>? defaultHeaders,
  http.Client? httpClientOverride,
}) {
  return createNhostFerryClientForAuth(
    nhostGqlEndpointUrl,
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
/// {@macro nhost.graphqlClient.gqlCache}
///
/// {@macro nhost.graphqlClient.defaultHeaders}
///
/// {@macro nhost.graphqlClient.httpClientOverride}
ferry.Client createNhostFerryClientForAuth(
  String nhostGqlEndpointUrl,
  Auth nhostAuth, {
  ferry.Cache? gqlCache,
  Map<String, String>? defaultHeaders,
  http.Client? httpClientOverride,
}) {
  return ferry.Client(
    link: combinedLinkForNhost(
      nhostGqlEndpointUrl,
      nhostAuth,
      defaultHeaders: defaultHeaders,
      httpClientOverride: httpClientOverride,
    ),
    cache: gqlCache,
  );
}
