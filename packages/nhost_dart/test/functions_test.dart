import 'dart:convert';

import 'package:nhost_dart/nhost_dart.dart';
import 'package:test/test.dart';

import 'setup.dart';

void main() async {
  NhostClient client;
  late FunctionsClient functions;

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

  group('functions client', () {
    test('receives expected result with every HTTP method', () async {
      for (final method in ['get', 'put', 'post', 'delete']) {
        final res = await functions.callFunction(
          '/test_function',
          httpMethod: method,
          query: {'arg': 'query content'},
          jsonBody: {'arg': 'body content'},
        );

        expect(res.request?.method, method);
        final jsonRes = jsonDecode(res.body) as Map<String, dynamic>;
        expect(
          jsonRes['receivedArgs'],
          equals(['body content', 'query content']),
        );
      }
    });

    test('fails on non-existent functions', () {
      expect(
        () => functions.callFunction('/no_such_function'),
        throwsA(isA<ApiException>()
            .having((err) => err.statusCode, 'statusCode', 404)),
      );
    });

    test('fails if the function throws', () {
      expect(
        () => functions.callFunction('/throwing_function'),
        throwsA(isA<ApiException>()
            .having((err) => err.statusCode, 'statusCode', 500)),
      );
    });
  });
}
