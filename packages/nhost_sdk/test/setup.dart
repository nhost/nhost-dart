import 'package:nhost_dart_sdk/client.dart';

const apiUrl = 'http://localhost:3000';
const gqlUrl = 'http://localhost:8080/v1/graphql';

NhostClient createTestClient() => NhostClient(baseUrl: apiUrl);
