library flutter_nhost_graphql;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_nhost_auth/flutter_nhost_auth.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:nhost_dart_sdk/nhost_dart_sdk.dart';
import 'package:web_socket_channel/io.dart';

/// Provides a GraphQL connection the subtree.
class NhostGraphQLProvider extends StatefulWidget {
  NhostGraphQLProvider({
    Key key,
    @required this.gqlEndpointUrl,
    this.auth,
    this.child,
  }) : super(key: key);

  /// The Nhost GQL URL
  /// TODO(shyndman): Console URL
  final String gqlEndpointUrl;

  /// Optional. If not provided, will be requested from ancestry using
  /// [NhostAuth.of(BuildContext)]
  final Auth auth;
  final Widget child;

  @override
  _NhostGraphQLProviderState createState() => _NhostGraphQLProviderState();
}

class _NhostGraphQLProviderState extends State<NhostGraphQLProvider> {
  ValueNotifier<GraphQLClient> clientNotifier;

  @override
  void initState() {
    super.initState();
    clientNotifier = ValueNotifier(null);
  }

  @override
  void didUpdateWidget(covariant NhostGraphQLProvider oldWidget) {
    super.didUpdateWidget(oldWidget);

    clientNotifier.value = generateGraphQLClient(
      widget.gqlEndpointUrl,
      widget.auth ?? NhostAuth.of(context),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    clientNotifier.value = generateGraphQLClient(
      widget.gqlEndpointUrl,
      widget.auth ?? NhostAuth.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: clientNotifier,
      child: widget.child,
    );
  }
}

/// Constructs a GQL client from...
GraphQLClient generateGraphQLClient(String gqlEndpointUrl, Auth auth) {
  if (auth == null) {
    return null;
  }

  final gqlEndpointUri = Uri.parse(gqlEndpointUrl);
  final authorizationHeaderValue = 'Bearer ${auth.jwt}';

  Link httpLink = HttpLink(gqlEndpointUri.toString());
  if (auth.isAuthenticated == true) {
    httpLink = AuthLink(
      getToken: () => authorizationHeaderValue,
    ).concat(httpLink);
  }

  final wsLink = WebSocketLink(
    gqlEndpointUri
        .replace(scheme: gqlEndpointUri.scheme == 'https' ? 'wss' : 'ws')
        .toString(),
    config: SocketClientConfig(
      connect: (url, protocols) => IOWebSocketChannel.connect(
        url,
        protocols: protocols,
        headers: {
          if (auth.isAuthenticated == true)
            HttpHeaders.authorizationHeader: authorizationHeaderValue,
        },
      ),
    ),
  );

  // TODO(shyndman): Do we need an equivalent for request.isDefinition?
  httpLink.split((request) => request.isSubscription, wsLink, httpLink);

  return GraphQLClient(link: httpLink, cache: GraphQLCache());
}
