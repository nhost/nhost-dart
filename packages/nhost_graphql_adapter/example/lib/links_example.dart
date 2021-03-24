/// Demonstrates how to construct your own client by composing custom [Link]s
/// along with the links provided by this package.
library links_example;

import 'dart:async';

import 'package:graphql/client.dart';
import 'package:nhost_sdk/nhost_sdk.dart';
import 'package:nhost_graphql_adapter/nhost_graphql_adapter.dart';

import 'todo_example.dart';

// Both of these URLs can be found in your nhost.io console, under the project
// you wish to connect to.

const backendEndpoint = 'https://backend-5e69d1d7.nhost.app';
const graphQLEndpoint = 'https://hasura-5e69d1d7.nhost.app/v1/graphql';

final myTodosQuery = gql(r'''
  query {
    todos {
      id
      name
      is_completed
      user_id
      created_at
      updated_at
    }
  }
''');

void main() async {
  final nhostClient = NhostClient(baseUrl: backendEndpoint);

  // The Nhost "terminating link" (the point at which requests are sent). We're
  // going to build links that execute on requests before this point is reached.
  final nhostLink = combinedLinkForNhost(
    graphQLEndpoint,
    nhostClient.auth,
  );

  // Create a new custom link that logs all requests and responses passing
  // through it
  final loggingMiddleware = Link.function((request, [nextLink]) {
    print('REQUEST: $request');
    return nextLink(request).transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          print('RESPONSE: $data');
          sink.add(data);
        },
      ),
    );
  });

  // Construct a GraphQL client using the composed link
  final gqlClient = GraphQLClient(
    link: loggingMiddleware.concat(nhostLink),
    cache: GraphQLCache(),
  );

  // Now we query, and will see logs printed to the console
  await gqlClient.query(QueryOptions(
    document: todosQuery,
  ));

  nhostClient.close();
}
