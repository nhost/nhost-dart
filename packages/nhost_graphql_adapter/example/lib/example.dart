import 'package:graphql/client.dart';
import 'package:nhost_dart_sdk/client.dart';
import 'package:nhost_graphql_adapter/nhost_graphql_adapter.dart';

// Both of these URLs can be found in your nhost.io console, under the project
// you wish to connect to.
const backendEndpoint = 'https://backend-5e69d1d7.nhost.app';
const graphQLEndpoint = 'https://hasura-5e69d1d7.nhost.app/v1/graphql';

void main() async {
  // Set up the Nhost and GraphQL clients
  final nhostClient = NhostClient(baseUrl: backendEndpoint);
  final graphqlClient = createNhostGraphQLClient(
    graphQLEndpoint,
    nhostClient.auth,
  );

  var todosStream = graphqlClient.subscribe(SubscriptionOptions(
    document: gql('''
      subscription {
        todos {
          id
          name
          is_completed
          created_at
          updated_at
        }
      }
    '''),
  ));
  final firstTodoResult = await todosStream.first;
  assert(firstTodoResult.hasException);

  //
  final myTodosQuery = gql(r'''
    query MyTodos {
      todos {
        id
        name
        is_completed
        created_at
        updated_at
      }
    }
  ''');

  // Run a query, unauthenticated
  var queryResult = await graphqlClient.query(
    QueryOptions(document: myTodosQuery),
  );

  // This failed, because we're not authenticated
  assert(queryResult.hasException);

  // Now authenticate...
  await nhostClient.auth
      .login(email: 'scott@madewithfelt.com', password: 'foofoo');

  // ...and try again, authenticated
  queryResult = await graphqlClient.query(
    QueryOptions(document: myTodosQuery),
  );

  // Success!
  print(queryResult.data['todos']);

  // Do the same with the stream
  todosStream = graphqlClient.subscribe(SubscriptionOptions(
    document: gql('''
      subscription {
        todos {
          id
          name
          is_completed
          created_at
          updated_at
        }
      }
    '''),
  ));

  // Print the next 5 updates (jump into your Hasura console and make some
  // changes)
  await for (final latestQueryResult in todosStream.take(5)) {
    print(latestQueryResult.data['todos']);
  }

  nhostClient.close();
}
