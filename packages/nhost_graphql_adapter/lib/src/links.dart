import 'dart:io';

import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:nhost_dart_sdk/client.dart';

/// Creates an HTTP link that configures automatically based on [nhostAuth]'s
/// authentication state.
///
/// [httpClientOverride] can be provided to customize the network request, such
/// as to configure proxies, introduce interceptors, etc.
Link httpLinkForNhost(
  String nhostGqlEndpointUrl,
  Auth nhostAuth, {
  http.Client httpClientOverride,
  Map<String, String> defaultHeaders,
}) {
  final unauthenticatedLink = HttpLink(
    nhostGqlEndpointUrl,
    httpClient: httpClientOverride,
    defaultHeaders: defaultHeaders,
  );
  final authenticatedLink = AuthLink(
    getToken: () => 'Bearer ${nhostAuth.jwt}',
  ).concat(unauthenticatedLink);

  return Link.split(
    (request) => nhostAuth.isAuthenticated == true,
    authenticatedLink,
    unauthenticatedLink,
  );
}

/// Creates a web socket link that configures automatically based on
/// [nhostAuth]'s authentication state.
Link webSocketLinkForNhost(
  String nhostGqlEndpointUrl,
  Auth nhostAuth, {
  Map<String, String> defaultHeaders,
}) {
  final uri = Uri.parse(nhostGqlEndpointUrl);

  final wsEndpointUri =
      uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws').toString();

  final unauthenticatedLink = WebSocketLink(wsEndpointUri);
  final authenticatedLink = WebSocketLink(
    wsEndpointUri,
    config: SocketClientConfig(
      autoReconnect: true,
      initialPayload: () {
        return {
          'headers': {
            ...?defaultHeaders,
            HttpHeaders.authorizationHeader: 'Bearer ${nhostAuth.jwt}',
          }
        };
      },
    ),
  );

  return Link.split(
    (request) => nhostAuth.isAuthenticated == true,
    authenticatedLink,
    unauthenticatedLink,
  );
}
