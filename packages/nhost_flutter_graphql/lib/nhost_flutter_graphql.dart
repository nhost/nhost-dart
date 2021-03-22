library nhost_flutter_graphql;

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:nhost_dart_sdk/client.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';
import 'package:nhost_graphql_adapter/nhost_graphql_adapter.dart';

export 'package:nhost_dart_sdk/client.dart';
export 'package:nhost_flutter_auth/nhost_flutter_auth.dart';

/// Provides a [GraphQLProvider] to this widget's subtree, configured to access
/// Nhost.
///
/// Nhost authentication information can be provided to the
/// [NhostGraphQLProvider] in one of two ways:
///
/// 1. By supplying the [nhostClient] argument.
/// 2. Through an [NhostAuthProvider] widget somewhere in this widget's
///    ancestry.
///
/// In either case, authentication changes are observed, and any changes will
/// update the GraphQL client accordingly.
class NhostGraphQLProvider extends StatefulWidget {
  NhostGraphQLProvider({
    Key key,
    @required this.gqlEndpointUrl,
    this.nhostClient,
    this.child,
  })  : assert(gqlEndpointUrl != null),
        super(key: key);

  /// The Nhost GQL URL
  final String gqlEndpointUrl;

  /// Optional. If not provided, the necessary information will be requested
  /// from ancestry using [NhostAuth.of(BuildContext)]
  final NhostClient nhostClient;
  final Widget child;

  @override
  _NhostGraphQLProviderState createState() => _NhostGraphQLProviderState();
}

class _NhostGraphQLProviderState extends State<NhostGraphQLProvider> {
  ValueNotifier<GraphQLClient> clientNotifier;
  Auth _lastAuth;

  @override
  void initState() {
    super.initState();
    clientNotifier = ValueNotifier(null);
  }

  Auth get currentNhostAuth =>
      widget.nhostClient.auth ?? NhostAuthProvider.of(context);

  @override
  void didUpdateWidget(covariant NhostGraphQLProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rebuildGraphQLClientIfNecessary(
        force: widget.gqlEndpointUrl != oldWidget.gqlEndpointUrl);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebuildGraphQLClientIfNecessary();
  }

  /// If the Auth instance doesn't change, we don't need to rebuild the GraphQL
  /// client, as the `Link`s constructed in [createNhostGraphQLClientForAuth]
  /// will automatically reflect authentication state.
  ///
  /// If the instance changes, it means we're dealing with an entirely new
  /// client, and the `Link`s themselves need rebuilding.
  void _rebuildGraphQLClientIfNecessary({bool force = false}) {
    if (force || _lastAuth != currentNhostAuth) {
      clientNotifier.value = createNhostGraphQLClientForAuth(
        widget.gqlEndpointUrl,
        _lastAuth = currentNhostAuth,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: clientNotifier,
      child: NhostAuthProvider(
        auth: _lastAuth,
        child: widget.child,
      ),
    );
  }
}
