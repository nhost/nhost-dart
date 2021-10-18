import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:nhost_graphql_adapter/nhost_graphql_adapter.dart';
import 'package:nhost_sdk/nhost_sdk.dart';

class GqlAdminTestHelper {
  GqlAdminTestHelper({
    required String apiUrl,
    required String gqlUrl,
    http.Client? httpClientOverride,
  }) {
    // Used to verify, retrieve, or clear backend state.
    client = createNhostGraphQLClient(
      gqlUrl,
      NhostClient(baseUrl: apiUrl),
      defaultHeaders: {
        'X-Hasura-Admin-Secret': '123456',
      },
      httpClientOverride: httpClientOverride,
    );
  }

  late GraphQLClient client;

  /// Clears the users table in the test backend
  Future<QueryResult> clearUsers() async {
    return await client.mutate(clearUsersMutation);
  }

  Future<String> getChangeTicketForUser(String userId) async {
    final result = await client.query(
      QueryOptions(
        document: queryChangeTicketForUser,
        variables: {
          'userId': userId,
        },
      ),
    );
    return result.data!['users'].first['account']['ticket'];
  }
}

final clearUsersMutation = MutationOptions(
  document: gql('''
    mutation clear_users {
      delete_users(where: {}) {
        affected_rows
      }
    }
  '''),
);

final queryChangeTicketForUser = gql(r'''
  query ChangeTickerForUser($userId: uuid!) {
    users(where: {id: {_eq: $userId}}) {
      account {
        ticket
      }
    }
  }
''');
