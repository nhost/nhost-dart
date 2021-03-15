library nhost_flutter_graphql;

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:nhost_dart_sdk/client.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';
import 'package:nhost_graphql_adapter/nhost_graphql.dart';

export 'package:nhost_flutter_auth/nhost_flutter_auth.dart';

/// Provides a GraphQL connection the subtree.
class NhostGraphQLProvider extends StatefulWidget {
  NhostGraphQLProvider({
    Key key,
    @required this.gqlEndpointUrl,
    this.nhostAuth,
    this.child,
  })  : assert(gqlEndpointUrl != null),
        super(key: key);

  /// The Nhost GQL URL
  final String gqlEndpointUrl;

  /// Optional. If not provided, will be requested from ancestry using
  /// [NhostAuth.of(BuildContext)]
  final Auth nhostAuth;
  final Widget child;

  @override
  _NhostGraphQLProviderState createState() => _NhostGraphQLProviderState();
}

class _NhostGraphQLProviderState extends State<NhostGraphQLProvider> {
  ValueNotifier<GraphQLClient> clientNotifier;
  Auth _auth;

  @override
  void initState() {
    super.initState();
    clientNotifier = ValueNotifier(null);
  }

  Auth updateAuth() {
    return _auth = widget.nhostAuth ?? NhostAuth.of(context);
  }

  @override
  void didUpdateWidget(covariant NhostGraphQLProvider oldWidget) {
    super.didUpdateWidget(oldWidget);

    clientNotifier.value = createNhostGraphQLClient(
      widget.gqlEndpointUrl,
      updateAuth(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    clientNotifier.value = createNhostGraphQLClient(
      widget.gqlEndpointUrl,
      updateAuth(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: clientNotifier,
      child: NhostAuth(
        nhostAuth: _auth,
        child: widget.child,
      ),
    );
  }
}
