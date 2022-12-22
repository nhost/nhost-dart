import 'package:gql/ast.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_http_link/gql_http_link.dart';
import 'package:gql_link/gql_link.dart';
import 'package:gql_websocket_link/gql_websocket_link.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:nhost_gql_links/src/logging.dart';
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
  NhostClient nhostClient, {
  Map<String, String>? defaultHeaders,
  http.Client? httpClientOverride,
}) {
  return combinedLinkForNhostAuth(
    nhostClient.gqlEndpointUrl,
    nhostClient.auth,
    defaultHeaders: defaultHeaders,
    httpClientOverride: httpClientOverride,
  );
}

/// Creates a link that that configures automatically based on [nhostAuth]'s
/// authentication state. The returned link will select HTTP or Web Socket
/// transport as appropriate based on the GQL operation type.
///
/// {@template nhost.links.nhostGqlEndpointUrl}
/// [nhostGqlEndpointUrl] can be found at [NhostClient.gqlEndpointUrl].
/// {@endtemplate}
///
/// {@macro nhost.links.defaultHeaders}
///
/// {@macro nhost.links.httpClientOverride}
Link combinedLinkForNhostAuth(
  String nhostGqlEndpointUrl,
  AuthClient nhostAuth, {
  Map<String, String>? defaultHeaders,
  http.Client? httpClientOverride,
}) {
  return Link.split(
    (Request request) {
      final document = request.operation.document;
      final operationDefs =
          document.definitions.whereType<OperationDefinitionNode>().toList();
      final operationTypes = operationDefs.map((def) => def.type).toSet();

      log.finest(
          () => 'Issuing request, operations=${operationDefs.toLogString()}');

      // If any of the operations in the request are subscriptions, we forward
      // the entire request along to the websocket
      return operationTypes.contains(OperationType.subscription);
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

/// The code sent to the server when the socket closes in order to send new
/// authentication information.
///
/// This is defined in dart:io, but we want to avoid that so we can build for
/// the web.
@visibleForTesting
const webSocketNormalCloseCode = 1000;

/// Creates an HTTP link that configures automatically based on [nhostAuth]'s
/// authentication state.
///
/// {@macro nhost.links.nhostGqlEndpointUrl}
///
/// {@macro nhost.links.defaultHeaders}
///
/// {@macro nhost.links.httpClientOverride}
Link httpLinkForNhost(
  String nhostGqlEndpointUrl,
  AuthClient nhostAuth, {
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
    if (nhostAuth.authenticationState == AuthenticationState.signedIn) {
      request = request.updateContextEntry<HttpLinkHeaders>(
        (entry) => HttpLinkHeaders(
          headers: {
            ...?entry?.headers,
            'Authorization': 'Bearer ${nhostAuth.accessToken}',
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
/// {@macro nhost.links.nhostGqlEndpointUrl}
///
/// [defaultHeaders] (optional) A set of headers that will be provided in the
/// initial payload when opening the socket.
Link webSocketLinkForNhost(
  String nhostGqlEndpointUrl,
  AuthClient nhostAuth, {
  Map<String, String>? defaultHeaders = const {},
  @visibleForTesting ChannelGenerator? testChannelGenerator,
  @visibleForTesting Duration? testInactivityTimeout,
  @visibleForTesting Duration testReconnectTimeout = const Duration(seconds: 3),
}) {
  final uri = Uri.parse(nhostGqlEndpointUrl);
  final wsEndpointUri =
      uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws');

  WebSocketChannel? channel;
  final channelGenerator = testChannelGenerator != null
      ? (() async => channel = await testChannelGenerator()) as ChannelGenerator
      : () {
          log.finest('Creating GraphQL web socket, uri=$wsEndpointUri');
          return channel = WebSocketChannel.connect(
            wsEndpointUri,
            protocols: ['graphql-ws'],
          );
        };

  // If authentication state changes, we reconnect the socket, which will also
  // re-evaluate the initialPayload to provide the auth header if available.
  nhostAuth.addTokenChangedCallback(() {
    if (channel != null) {
      log.finest('Reconnecting GraphQL web socket as result of token change');
      channel?.sink.close(webSocketNormalCloseCode, 'Auth changed');
    }
  });
  final webSocketLink = WebSocketLink(
    /* url — provided via channelGenerator */ null,
    autoReconnect: true,
    channelGenerator: channelGenerator,
    initialPayload: () => {
      'headers': {
        ...?defaultHeaders,
        if (nhostAuth.authenticationState == AuthenticationState.signedIn)
          'Authorization': 'Bearer ${nhostAuth.accessToken}',
      },
    },
    inactivityTimeout: testInactivityTimeout,
    reconnectInterval: testReconnectTimeout,
  );

  return webSocketLink;
}
