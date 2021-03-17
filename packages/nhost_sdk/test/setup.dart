import 'dart:async';

import 'package:betamax/betamax.dart';
import 'package:http/http.dart' as http;
import 'package:nhost_dart_sdk/client.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:test_api/src/backend/invoker.dart';

import 'test_helpers.dart';

const apiUrl = 'http://localhost:3000';
const gqlUrl = 'http://localhost:8080/v1/graphql';

const recordFixturesEnvVariableName = 'RECORD_HTTP_FIXTURES';

/// Initializes Betamax, which is responsible for HTTP fixtures
void initializeHttpFixturesForSuite(String suiteName) {
  final recordFixtures = bool.fromEnvironment(recordFixturesEnvVariableName);
  Betamax.configure(
    suiteName: suiteName,
    mode: recordFixtures ? Mode.recording : Mode.playback,
    cassettePath: join(getTestDirectory(), 'http_fixtures'),
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

Future<http.Client> setUpApiTest() async {
  final currentTest = Invoker.current.liveTest;
  if (currentTest.test.metadata.tags.contains(Betamax.noPlaybackTag)) {
    return http.Client();
  }

  final client = Betamax.clientForTest();
  final currentTestPath = [
    ...currentTest.groups
        // Skip root group
        .skip(1)
        .map((g) => g.name),
    currentTest.individualName,
  ];
  await Betamax.setCassette(currentTestPath);
  return client;
}

void tearDownApiTest() {}
