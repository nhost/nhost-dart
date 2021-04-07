import 'dart:async';

import 'package:betamax/betamax.dart';
import 'package:http/http.dart' as http;
import 'package:nhost_sdk/nhost_sdk.dart';
import 'package:test/test.dart';
import 'package:test_api/src/backend/invoker.dart';

const apiUrl = 'http://localhost:3000';
const gqlUrl = 'http://localhost:8080/v1/graphql';

const recordFixturesEnvVariableName = 'RECORD_HTTP_FIXTURES';

/// Initializes Betamax, which is responsible for HTTP fixtures
void initializeHttpFixturesForSuite(String suiteName) {
  final recordFixtures = bool.fromEnvironment(recordFixturesEnvVariableName);
  Betamax.configureSuite(
    suiteName: suiteName,
    mode: recordFixtures ? Mode.recording : Mode.playback,
  );
}

/// Creates an Nhost client for a single test.
///
/// This method must be called from a test's [setUp] method, or a test body.
NhostClient createApiTestClient(http.Client httpClient) {
  return NhostClient(
    baseUrl: apiUrl,
    httpClientOverride: httpClient,
  );
}

const noHttpFixturesTag = 'no-http-fixtures';

Future<http.Client> setUpApiTest() async {
  final currentTest = Invoker.current!.liveTest;
  if (currentTest.test.metadata.tags.contains(noHttpFixturesTag)) {
    return http.Client();
  }

  return Betamax.clientForTest();
}
