import 'package:gql/ast.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_http_link/gql_http_link.dart';
import 'package:gql_link/gql_link.dart';
import 'package:gql_websocket_link/gql_websocket_link.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:nhost_sdk/nhost_sdk.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  Map<String, String>? defaultHeaders,
  http.Client? httpClientOverride,
}) {
  return Link.split(
    (Request request) {
      final document = request.operation.document;
      // If any of the operations in the request are subscriptions, we forward
      // the entire request along to the websocket
      return document.definitions
          .whereType<OperationDefinitionNode>()
          .any((def) => def.type == OperationType.subscription);
    },
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
  http.Client? httpClientOverride,
  Map<String, String>? defaultHeaders = const {},
}) {
  final unauthenticatedLink = HttpLink(
    nhostGqlEndpointUrl,
    httpClient: httpClientOverride,
    defaultHeaders: defaultHeaders ?? const {},
  );

  // Introduce an Authorization header
  final addAuthenticationLink = Link.function((request, [forward]) {
    if (nhostAuth.authenticationState == AuthenticationState.loggedIn) {
      request = request.updateContextEntry<HttpLinkHeaders>(
        (entry) => HttpLinkHeaders(
          headers: {
            ...?entry?.headers,
            'Authorization': 'Bearer ${nhostAuth.jwt}',
          },
        ),
      );
    }

    return forward!(request);
  });

  return Link.concat(addAuthenticationLink, unauthenticatedLink);
}

/// Creates a web socket link that configures (and reconfigures) automatically
/// based on [nhostAuth]'s authentication state.
///
/// [defaultHeaders] (optional) A set of headers that will be provided in the
/// initial payload when opening the socket.
Link webSocketLinkForNhost(
  String nhostGqlEndpointUrl,
  Auth nhostAuth, {
  Map<String, String>? defaultHeaders = const {},
  @visibleForTesting ChannelGenerator? testChannelGenerator,
  @visibleForTesting Duration? testInactivityTimeout,
  @visibleForTesting
      Duration testReconnectTimeout = const Duration(seconds: 10),
}) {
  final uri = Uri.parse(nhostGqlEndpointUrl);
  final wsEndpointUri =
      uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws');

  WebSocketChannel? channel;
  final channelGenerator = testChannelGenerator != null
      ? (() async => channel = await testChannelGenerator()) as ChannelGenerator
      : () => channel = WebSocketChannel.connect(wsEndpointUri);

  // If authentication state changes, we reconnect the socket, which will also
  // re-evaluate the initialPayload to provide the auth header if available.
  nhostAuth.addTokenChangedCallback(() {
    print('nhost: Auth token changed');
    if (channel != null) {
      print('nost: …reconnecting web socket');
      channel?.sink?.close(/* arbitrary */ 0, 'Auth changed');
    }
  });

  final webSocketLink = WebSocketLink(
    /* url — provided via channelGenerator */ null,
    autoReconnect: true,
    channelGenerator: channelGenerator,
    initialPayload: () => {
      'headers': {
        ...?defaultHeaders,
        if (nhostAuth.authenticationState == AuthenticationState.loggedIn)
          'Authorization': 'Bearer ${nhostAuth.jwt}',
      },
    },
    inactivityTimeout: testInactivityTimeout,
    reconnectInterval: testReconnectTimeout,
  );

  return webSocketLink;
}
