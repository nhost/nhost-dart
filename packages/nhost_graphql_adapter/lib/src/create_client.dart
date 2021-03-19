import 'dart:io';

import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:nhost_dart_sdk/client.dart';

import 'links.dart';

/// Constructs a GQL client for accessing Nhost.io's backend.
///
/// The connection will be configured to automatically reflect the logged in
/// state of [nhostAuth], and will change over time.
///
/// [gqlCache] (optional) the GraphQL cache to provide to the client. Defaults
/// to a basic [GraphQLCache] instance.
///
/// [defaultRequestHeaders] (optional) a map of headers that will accompany HTTP
/// requests and the initial web socket payload. Any matching headers set by the
/// client will overwrite the default values.
///
/// [httpClientOverride] (optional) can be provided in order to customize the
/// requests made by the Nhost APIs, which can be useful for proxy configuration
/// and debugging.
GraphQLClient createNhostGraphQLClient(
  String nhostGqlEndpointUrl,
  Auth nhostAuth, {
  GraphQLCache gqlCache,
  Map<String, String> defaultRequestHeaders,
  http.Client httpClientOverride,
}) {
  return GraphQLClient(
    link: Link.split(
      (request) => request.isSubscription,
      webSocketLinkForNhost(
        nhostGqlEndpointUrl,
        nhostAuth,
        defaultHeaders: defaultRequestHeaders,
      ),
      httpLinkForNhost(
        nhostGqlEndpointUrl,
        nhostAuth,
        defaultHeaders: defaultRequestHeaders,
        httpClientOverride: httpClientOverride,
      ),
    ),
    cache: gqlCache ?? GraphQLCache(),
  );
}
