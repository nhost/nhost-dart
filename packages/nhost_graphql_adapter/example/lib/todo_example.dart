/// A simple example that queries the "todos" table created in the Nhost Quick
/// Start (https://docs.nhost.io).
library simple_example;

import 'package:graphql/client.dart';
import 'package:nhost_graphql_adapter/nhost_graphql_adapter.dart';

import 'config.dart';

final todosQuery = gql(r'''
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
  // Set up the Nhost and GraphQL clients
  final nhostClient = NhostClient(
    subdomain: Subdomain(
      subdomain: subdomain,
      region: region,
    ),
  );
  final graphqlClient = createNhostGraphQLClient(nhostClient);

  // Run a query, unauthenticated
  var queryResult = await graphqlClient.query(
    QueryOptions(document: todosQuery),
  );

  // This failed, because we're not authenticated
  assert(queryResult.hasException);

  // Now authenticate...
  await nhostClient.auth
      .signInEmailPassword(email: 'scott@madewithfelt.com', password: 'foofoo');

  // ...and try again, authenticated
  queryResult = await graphqlClient.query(
    QueryOptions(document: todosQuery),
  );

  // Success!
  print(queryResult.data!['todos']);

  nhostClient.close();
}
