import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:nhost_dart/nhost_dart.dart';
import 'package:test/test.dart';

const subdomain = 'local';
const region = '';

final gqlUrl = createNhostServiceEndpoint(
  region: region,
  subdomain: subdomain,
  service: 'graphql',
);

const enableLoggingEnvVariableName = 'LOGGING';

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

/// Creates an Nhost client for a single test.
///
/// This method must be called from a test's [setUp] method, or a test body.
NhostClient createApiTestClient(
  http.Client httpClient, {
  AuthStore? authStore,
}) {
  return NhostClient(
    subdomain: Subdomain(
      subdomain: subdomain,
      region: region,
    ),
    httpClientOverride: httpClient,
    authStore: authStore,
  );
}
