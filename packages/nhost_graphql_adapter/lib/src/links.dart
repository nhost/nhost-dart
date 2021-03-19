import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:nhost_dart_sdk/client.dart';

/// Creates a link that that configures automatically based on [nhostClient]'s
/// authentication state, and will select HTTP or Web Socket transport as
/// appropriate.
///
/// {@template nhost.links.defaultHeaders}
/// [defaultHeaders] (optional) A set of headers that will be provided with
/// all requests passing through the link.
/// {@endtemplate}
///
/// {@template nhost.links.httpClientOverride}
/// [httpClientOverride] (optional) can be provided to customize the network
/// request, such as to configure proxies, introduce interceptors, etc.
/// {@endtemplate}
Link combinedLinkForNhost(
  String nhostGqlEndpointUrl,
  NhostClient nhostClient, {
  Map<String, String> defaultHeaders,
  http.Client httpClientOverride,
}) {
  return Link.split(
    (request) => request.isSubscription,
    webSocketLinkForNhost(
      nhostGqlEndpointUrl,
      nhostClient,
      defaultHeaders: defaultHeaders,
    ),
    httpLinkForNhost(
      nhostGqlEndpointUrl,
      nhostClient,
      defaultHeaders: defaultHeaders,
      httpClientOverride: httpClientOverride,
    ),
  );
}

/// Creates an HTTP link that configures automatically based on [nhostClient]'s
/// authentication state.
///
/// {@macro nhost.links.defaultHeaders}
///
/// {@macro nhost.links.httpClientOverride}
Link httpLinkForNhost(
  String nhostGqlEndpointUrl,
  NhostClient nhostClient, {
  http.Client httpClientOverride,
  Map<String, String> defaultHeaders = const {},
}) {
  final auth = nhostClient.auth;

  final unauthenticatedLink = HttpLink(
    nhostGqlEndpointUrl,
    httpClient: httpClientOverride,
    defaultHeaders: defaultHeaders ?? const {},
  );
  final authenticatedLink = AuthLink(
    getToken: () => 'Bearer ${auth.jwt}',
  ).concat(unauthenticatedLink);

  return Link.split(
    (request) => auth.isAuthenticated == true,
    authenticatedLink,
    unauthenticatedLink,
  );
}

/// Creates a web socket link that configures (and reconfigures) automatically
/// based on [nhostClient]'s authentication state.
///
/// [defaultHeaders] (optional) A set of headers that will be provided in the
/// initial payload when opening the socket.
Link webSocketLinkForNhost(
  String nhostGqlEndpointUrl,
  NhostClient nhostClient, {
  Map<String, String> defaultHeaders = const {},
}) {
  final auth = nhostClient.auth;

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
            if (auth.isAuthenticated == true)
              'authorization': 'Bearer ${auth.jwt}',
          }
        };
      },
    ),
  );

  // If authentication state changes, we reconnect the socket, which will also
  // re-evaluate the initialPayload providing (or not providing) the auth
  // header.
  auth.addTokenChangedCallback(() {
    webSocketLink.connectOrReconnect();
  });

  return webSocketLink;
}
