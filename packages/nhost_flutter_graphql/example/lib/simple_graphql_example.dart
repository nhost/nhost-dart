/// Demonstrates establishing a GraphQL connection, and using widgets from the
/// `graphql` package.
///
/// IMPORTANT: This example requires some setup to prepare the database tables
/// on the backend. See README.md for more information.
library simple_graphql_example;

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:nhost_flutter_graphql/nhost_flutter_graphql.dart';

import 'config.dart';

/// Client used to authenticate GraphQL requests
final nhostClient = NhostClient(
  subdomain: Subdomain(
    subdomain: subdomain,
    region: region,
  ),
);

void main() {
  runApp(const SimpleGqlExample());
}

class SimpleGqlExample extends StatelessWidget {
  const SimpleGqlExample({super.key});

  @override
  Widget build(BuildContext context) {
    // The NhostGraphQLProvider automatically provides connection information
    // to `graphql_flutter` widgets in its subtree.
    return NhostGraphQLProvider(
      nhostClient: nhostClient,
      child: MaterialApp(
        title: 'Nhost.io Simple Flutter GraphQL Example',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          // `Query`, along with other `graphql` widgets, automatically pick up
          // the connection information from the nearest `NhostGraphQLProvider`.
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Query(
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
                    return const Text('Loading…');
                  }

                  final todosList = result.data!['todos'] as List<dynamic>;
                  if (todosList.isEmpty) {
                    return const Text('No todos yet!');
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
        ),
      ),
    );
  }
}
