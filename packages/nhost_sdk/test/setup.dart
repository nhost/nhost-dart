import 'dart:async';
import 'dart:io';

import 'package:betamax/betamax.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:nhost_sdk/nhost_sdk.dart';
import 'package:test/test.dart';
import 'package:test_api/src/backend/invoker.dart';

const backendUrl = 'http://localhost:1337';
const gqlUrl = '$backendUrl/v1/graphql';

const enableLoggingEnvVariableName = 'LOGGING';
const recordFixturesEnvVariableName = 'RECORD_HTTP_FIXTURES';

/// Sets up logging if the appropriate env variable is set
void initLogging() {
  if (Platform.environment[enableLoggingEnvVariableName] == 'true') {
    Logger.root
      ..onRecord.listen((event) {
        print(event);
      })
      ..level = Level.ALL;
  } else {
    Logger.root.level = Level.OFF;
  }
}

/// Initializes Betamax, which is responsible for HTTP fixtures
void initializeHttpFixturesForSuite(String suiteName) {
  final recordFixtures =
      Platform.environment[recordFixturesEnvVariableName] == 'true';
  print(recordFixtures
      ? '[$suiteName] Recording HTTP'
      : '[$suiteName] Playing back HTTP fixtures');

  Betamax.configureSuite(
    suiteName: suiteName,
    mode: recordFixtures ? Mode.recording : Mode.playback,
  );
}

/// Creates an Nhost client for a single test.
///
/// This method must be called from a test's [setUp] method, or a test body.
NhostClient createApiTestClient(
  http.Client httpClient, {
  AuthStore? authStore,
}) {
  return NhostClient(
    backendUrl: backendUrl,
    httpClientOverride: httpClient,
    authStore: authStore,
  );
}

/// Tests tagged with this value will not record fixtures
const noHttpFixturesTag = 'no-http-fixtures';

Future<http.Client> setUpApiTest() async {
  final currentTest = Invoker.current!.liveTest;
  if (currentTest.test.metadata.tags.contains(noHttpFixturesTag)) {
    return http.Client();
  }

  return Betamax.clientForTest();
}
