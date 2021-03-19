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
/// The optional [httpClientOverride] parameter can be provided in order to
/// customize the requests made by the Nhost APIs, which can be useful for
/// proxy configuration and debugging.
///
/// [defaultRequestHeaders] are an optional map of headers that will accompany
/// HTTP and web socket requests. Any headers set by the client will overwrite
/// the default values.
GraphQLClient createNhostGraphQLClient(
  String nhostGqlEndpointUrl,
  Auth nhostAuth, {
  GraphQLCache gqlCache,
  Map<String, String> defaultRequestHeaders,
  http.Client httpClientOverride,
}) {
  return GraphQLClient(
    link: Link.split(
      // TODO(shyndman): Do we need an equivalent for request.isDefinition?
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
