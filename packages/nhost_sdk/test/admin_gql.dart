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
      NhostClient(backendUrl: apiUrl),
      defaultHeaders: {
        'X-Hasura-Admin-Secret': 'nhost-admin-secret',
      },
      httpClientOverride: httpClientOverride,
    );
  }

  late GraphQLClient client;

  /// Clears the users table in the test backend
  Future<QueryResult> clearUsers() async {
    return client.mutate(clearUsersMutation);
  }

  Future<FileMetadata?> getFileInfo(String id) async {
    final result = await client.query(QueryOptions(
      document: getFileByIdQuery,
      variables: {'id': id},
      fetchPolicy: FetchPolicy.networkOnly,
    ));

    final fileJson = result.data?['file'];
    return fileJson != null ? FileMetadata.fromJson(fileJson) : null;
  }

  Future<QueryResult> clearFiles() async {
    return client.mutate(clearFilesMutation);
  }
}

final clearUsersMutation = MutationOptions(
  document: gql('''
    mutation clear_users {
      deleteUsers(where: {}) {
        affected_rows
      }
    }
  '''),
);

final getFileByIdQuery = gql(r'''
  query ($id: uuid!) {
    file(id: $id) {
      id
      bucketId
      name
      size
      etag
      mimeType
      createdAt
    }
  }
''');

final clearFilesMutation = MutationOptions(
  document: gql('''
    mutation clear_files {
      deleteFiles(where: {}) {
        affected_rows
      }
    }
  '''),
);
