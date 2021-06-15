/// Demonstrates the creation and usage of a Ferry client connected to an Nhost
/// backend.
///
/// For more information on Ferry, check out https://ferrygraphql.com/
library nhost_ferry_adapter_example;

import 'package:nhost_ferry_adapter/nhost_ferry_adapter.dart';
import 'package:nhost_ferry_adapter_example/graphql/todos.req.gql.dart';
import 'package:nhost_sdk/nhost_sdk.dart';

const backendEndpoint = 'https://backend-5e69d1d7.nhost.app';
const graphQLEndpoint = 'https://hasura-5e69d1d7.nhost.app/v1/graphql';

void main() async {
  final nhostClient = NhostClient(baseUrl: backendEndpoint);
  final ferryClient = createNhostFerryClient(graphQLEndpoint, nhostClient);

  final response =
      // See graphql/todos.graphql for the query's definition
      await ferryClient.request(GGetAllTodosReqBuilder().build()).first;
  print(response.data);
}
