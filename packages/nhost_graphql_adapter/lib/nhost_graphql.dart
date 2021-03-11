import 'dart:io';

import 'package:graphql/client.dart';
import 'package:nhost_dart_sdk/client.dart';
import 'package:web_socket_channel/io.dart';

/// Constructs a GQL client for accessing Nhost.io's backend.
///
/// If you use graphql's link framework to modify requests and a preconfigured
/// client will not
///
/// The connection will be configured to automatically reflect the logged in
/// state of [nhostAuth], including changes over time.
GraphQLClient createNhostGraphQLClient(
  String nhostGqlEndpointUrl,
  Auth nhostAuth,
) {
  return GraphQLClient(
    link: Link.split(
      // TODO(shyndman): Do we need an equivalent for request.isDefinition?
      (request) => request.isSubscription,
      webSocketLinkForNhost(nhostGqlEndpointUrl, nhostAuth),
      httpLinkForNhost(nhostGqlEndpointUrl, nhostAuth),
    ),
    cache: GraphQLCache(),
  );
}

Link httpLinkForNhost(String nhostGqlEndpointUrl, Auth nhostAuth) {
  final unauthenticatedLink = HttpLink(nhostGqlEndpointUrl);
  final authenticatedLink = AuthLink(
    getToken: () => 'Bearer ${nhostAuth.jwt}',
  ).concat(unauthenticatedLink);

  return Link.split(
    (request) => nhostAuth.isAuthenticated,
    authenticatedLink,
    unauthenticatedLink,
  );
}

Link webSocketLinkForNhost(String nhostGqlEndpointUrl, Auth nhostAuth) {
  final uri = Uri.parse(nhostGqlEndpointUrl);
  final wsEndpointUri =
      uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws').toString();

  final unauthenticatedLink = WebSocketLink(wsEndpointUri);
  final authenticatedLink = WebSocketLink(
    wsEndpointUri,
    config: SocketClientConfig(
      connect: (url, protocols) => IOWebSocketChannel.connect(
        url,
        protocols: protocols,
        headers: {
          if (nhostAuth.isAuthenticated == true)
            HttpHeaders.authorizationHeader: 'Bearer ${nhostAuth.jwt}',
        },
      ),
    ),
  );

  return Link.split(
    (request) => nhostAuth.isAuthenticated,
    authenticatedLink,
    unauthenticatedLink,
  );
}
