/// Demonstrates how to construct your own client by composing custom [Link]s
/// along with the links provided by this package.
library links_example;

import 'dart:async';

import 'package:graphql/client.dart';
import 'package:nhost_graphql_adapter/nhost_graphql_adapter.dart';

import 'config.dart';
import 'todo_example.dart';

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
  final nhostClient = NhostClient(
    subdomain: subdomain,
    region: region,
  );

  // The Nhost "terminating link" (the point at which requests are sent). We're
  // going to build links that execute on requests before this point is reached.
  final nhostLink = combinedLinkForNhost(nhostClient);

  // Create a new custom link that logs all requests and responses passing
  // through it
  final loggingMiddleware = Link.function((request, [nextLink]) {
    print('REQUEST: $request');
    return nextLink!(request).transform(
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
