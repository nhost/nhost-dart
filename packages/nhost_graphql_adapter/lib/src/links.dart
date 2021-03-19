import 'dart:io';

import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:nhost_dart_sdk/client.dart';

/// Creates an HTTP link that configures automatically based on [nhostAuth]'s
/// authentication state.
///
/// [httpClientOverride] (optional) can be provided to customize the network
/// request, such as to configure proxies, introduce interceptors, etc.
///
/// [defaultHeaders] (optional) A set of headers that will be provided with
/// all requests passing through the link.
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

/// Creates a web socket link that configures (and reconfigures) automatically
/// based on [nhostAuth]'s authentication state.
///
/// [defaultHeaders] (optional) A set of headers that will be provided in the
/// initial payload when opening the socket.
Link webSocketLinkForNhost(
  String nhostGqlEndpointUrl,
  Auth nhostAuth, {
  Map<String, String> defaultHeaders,
}) {
  final uri = Uri.parse(nhostGqlEndpointUrl);
  final wsEndpointUri =
      uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws').toString();

  final webSocketLink = WebSocketLink(
    wsEndpointUri,
    config: SocketClientConfig(
      autoReconnect: true,
      initialPayload: () {
        return {
          'headers': {
            ...?defaultHeaders,
            if (nhostAuth.isAuthenticated == true)
              HttpHeaders.authorizationHeader: 'Bearer ${nhostAuth.jwt}',
          }
        };
      },
    ),
  );

  // If authentication state changes, we reconnect the socket, which will also
  // re-evaluate the initialPayload providing (or not providing) the auth
  // header.
  nhostAuth.addTokenChangedCallback(() {
    webSocketLink.connectOrReconnect();
  });

  return webSocketLink;
}
