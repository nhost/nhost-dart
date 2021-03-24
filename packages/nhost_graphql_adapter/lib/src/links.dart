import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:nhost_sdk/nhost_sdk.dart';

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
  Auth nhostAuth, {
  Map<String, String> defaultHeaders,
  http.Client httpClientOverride,
}) {
  return Link.split(
    (request) => request.isSubscription,
    webSocketLinkForNhost(
      nhostGqlEndpointUrl,
      nhostAuth,
      defaultHeaders: defaultHeaders,
    ),
    httpLinkForNhost(
      nhostGqlEndpointUrl,
      nhostAuth,
      defaultHeaders: defaultHeaders,
      httpClientOverride: httpClientOverride,
    ),
  );
}

/// Creates an HTTP link that configures automatically based on [nhostAuth]'s
/// authentication state.
///
/// {@macro nhost.links.defaultHeaders}
///
/// {@macro nhost.links.httpClientOverride}
Link httpLinkForNhost(
  String nhostGqlEndpointUrl,
  Auth nhostAuth, {
  http.Client httpClientOverride,
  Map<String, String> defaultHeaders = const {},
}) {
  final unauthenticatedLink = HttpLink(
    nhostGqlEndpointUrl,
    httpClient: httpClientOverride,
    defaultHeaders: defaultHeaders ?? const {},
  );
  final authenticatedLink = AuthLink(
    getToken: () => 'Bearer ${nhostAuth.jwt}',
  ).concat(unauthenticatedLink);

  return Link.split(
    (request) => nhostAuth.authenticationState == AuthenticationState.loggedIn,
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
  Map<String, String> defaultHeaders = const {},
  @visibleForTesting WebSocketConnect testWebSocketConnectOverride,
  @visibleForTesting
      Duration testInactivityTimeout = const Duration(seconds: 1),
}) {
  final uri = Uri.parse(nhostGqlEndpointUrl);
  final wsEndpointUri =
      uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws').toString();

  final webSocketLink = WebSocketLink(
    wsEndpointUri,
    config: SocketClientConfig(
      autoReconnect: true,
      connect:
          testWebSocketConnectOverride ?? SocketClientConfig.defaultConnect,
      queryAndMutationTimeout: testWebSocketConnectOverride != null
          ? testInactivityTimeout // Fast timeouts for tests
          : const Duration(seconds: 10),
      initialPayload: () {
        return {
          'headers': {
            ...?defaultHeaders,
            if (nhostAuth.authenticationState == AuthenticationState.loggedIn)
              'Authorization': 'Bearer ${nhostAuth.jwt}',
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
