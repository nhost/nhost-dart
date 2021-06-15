/// Demonstrates how to construct your own client by composing custom [Link]s
/// along with the links provided by this package.
library links_example;

import 'dart:async';

import 'package:gql/language.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_link/gql_link.dart';
import 'package:nhost_gql_links/nhost_gql_links.dart';
import 'package:nhost_sdk/nhost_sdk.dart';

// Both of these URLs can be found in your nhost.io console, under the project
// you wish to connect to.

const backendEndpoint = 'https://backend-5e69d1d7.nhost.app';
const graphQLEndpoint = 'https://hasura-5e69d1d7.nhost.app/v1/graphql';

final myTodosQuery = parseString(r'''
  query {
    todos {
      id
      name
      is_completed
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
    return nextLink!(request).transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          print('RESPONSE: $data');
          sink.add(data);
        },
      ),
    );
  });

  // Combine the two links we've created into a pipeline. This is what you'd
  // provide to your client.
  final link = loggingMiddleware.concat(nhostLink);

  // Query the link directly (usually this would be done through a client
  // object)
  await link
      .request(Request(operation: Operation(document: myTodosQuery)))
      .first;

  nhostClient.close();
}
