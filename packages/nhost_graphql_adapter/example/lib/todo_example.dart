/// A simple example that queries the "todos" table created in the Nhost Quick
/// Start (https://docs.nhost.io/get-started).
library simple_example;

import 'package:graphql/client.dart';
import 'package:nhost_sdk/nhost_sdk.dart';
import 'package:nhost_graphql_adapter/nhost_graphql_adapter.dart';

// Both of these URLs can be found in your nhost.io console, under the project
// you wish to connect to.

const backendEndpoint = 'https://backend-5e69d1d7.nhost.app';
const graphQLEndpoint = 'https://hasura-5e69d1d7.nhost.app/v1/graphql';

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
  final nhostClient = NhostClient(baseUrl: backendEndpoint);
  final graphqlClient = createNhostGraphQLClient(
    graphQLEndpoint,
    nhostClient,
  );

  // Run a query, unauthenticated
  var queryResult = await graphqlClient.query(
    QueryOptions(document: todosQuery),
  );

  // This failed, because we're not authenticated
  assert(queryResult.hasException);

  // Now authenticate...
  await nhostClient.auth
      .login(email: 'scott@madewithfelt.com', password: 'foofoo');

  // ...and try again, authenticated
  queryResult = await graphqlClient.query(
    QueryOptions(document: todosQuery),
  );

  // Success!
  print(queryResult.data!['todos']);

  nhostClient.close();
}
