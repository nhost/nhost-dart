import 'dart:convert';

import 'package:nhost_sdk/nhost_sdk.dart';
import 'package:test/test.dart';

import 'setup.dart';

void main() async {
  NhostClient client;
  late Functions functions;

  setUpAll(() {
    initLogging();
    initializeHttpFixturesForSuite('functions');
  });

  setUp(() async {
    // Get a recording/playback HTTP client from Betamax
    final httpClient = await setUpApiTest();

    // Create a fresh client
    client = createApiTestClient(httpClient);

    // Provide a few values to tests
    functions = client.functions;
  });

  group('function client', () {
    test('sends data via the body and query string', () async {
      final res = await functions.invoke(
        '/test_function',
        query: {'arg': 'query content'},
        jsonBody: {'arg': 'body content'},
      );
      final jsonRes = jsonDecode(res.body) as Map<String, dynamic>;
      expect(
        jsonRes['receivedArgs'],
        equals(['body content', 'query content']),
      );
    });

    test('fails on non-existent functions', () {
      expect(
        () => functions.invoke('/no_such_function'),
        throwsA(isA<ApiException>()
            .having((err) => err.statusCode, 'statusCode', 404)),
      );
    });

    test('fails if the function throws', () {
      expect(
        () => functions.invoke('/throwing_function'),
        throwsA(isA<ApiException>()
            .having((err) => err.statusCode, 'statusCode', 500)),
      );
    });
  });
}
