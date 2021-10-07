/// Demonstrates establishing a GraphQL connection, and using widgets from the
/// `graphql` package.
///
/// IMPORTANT: This example requires some setup to prepare the database tables
/// on the backend. See README.md for more information.
library simple_graphql_example;

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:nhost_flutter_graphql/nhost_flutter_graphql.dart';

// IMPORTANT: Fill in these values with the Backend and GraphQL URL found on
// your Nhost project page.

const nhostApiUrl = 'https://backend-5e69d1d7.nhost.app';
const nhostGraphQLUrl = 'https://hasura-5e69d1d7.nhost.app/v1/graphql';

/// Client used to authenticate GraphQL requests
final nhostClient = NhostClient(baseUrl: nhostApiUrl);

void main() {
  runApp(SimpleGqlExample());
}

class SimpleGqlExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // The NhostGraphQLProvider automatically provides connection information
    // to `graphql_flutter` widgets in its subtree.
    return NhostGraphQLProvider(
      nhostClient: nhostClient,
      gqlEndpointUrl: nhostGraphQLUrl,
      child: MaterialApp(
        title: 'Nhost.io Simple Flutter GraphQL Example',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          // `Query`, along with other `graphql` widgets, automatically pick up
          // the connection information from the nearest `NhostGraphQLProvider`.
          body: Query(
            options: QueryOptions(
              document: gql('''
                  query {
                    todos {
                      name
                      is_completed
                      created_at
                      updated_at
                    }
                  }
                '''),
            ),
            builder: (result, {fetchMore, refetch}) {
              if (result.hasException) {
                return ErrorWidget(result.exception!);
              }

              if (result.isLoading) {
                return Text('Loading…');
              }

              final todosList = result.data!['todos'] as List<dynamic>;
              if (todosList.isEmpty) {
                return Text('No todos yet!');
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in todosList)
                    Text(
                      '${item['name'].trim()}, '
                      'isCompleted: ${item['is_completed']}',
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
