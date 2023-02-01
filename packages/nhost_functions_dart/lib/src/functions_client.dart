import 'package:http/http.dart' as http;
import 'package:nhost_sdk/nhost_sdk.dart';

import 'logging.dart';

/// Client for calling Nhost serverless functions.
///
/// See https://docs.nhost.io/platform/serverless-functions for more info.
class FunctionsClient {
  /// {@macro nhost.api.NhostClient.subdomain}
  ///
  /// {@macro nhost.api.NhostClient.serviceUrls}
  ///
  /// {@macro nhost.api.NhostClient.httpClientOverride}
  FunctionsClient({
    Subdomain? subdomain,
    String? functionsUrl,
    UserSession? session,
    http.Client? httpClient,
  })  : _apiClient = ApiClient(
          Uri.parse(
            subdomain != null
                ? createNhostServiceEndpoint(
                    subdomain: subdomain.subdomain,
                    region: subdomain.region,
                    service: 'functions',
                  )
                : functionsUrl!,
          ),
          httpClient: httpClient ?? http.Client(),
        ),
        _session = session ?? UserSession() {
    if ((subdomain == null && functionsUrl == null) ||
        (subdomain != null && functionsUrl != null)) {
      throw ArgumentError.notNull(
        'You have to pass either [Subdomain] or [FunctionUrl]',
      );
    }
  }
  final ApiClient _apiClient;
  final UserSession _session;

  /// Invokes the serverless function at [url].
  ///
  /// By default, the serverless function is invoked using an HTTP POST, so both
  /// a request body and query variables can be provided.
  ///
  /// The HTTP method used for the call can be overridden via [httpMethod].
  ///
  /// Throws an [ApiException] if a failure occurs.
  Future<http.Response> callFunction(
    String url, {
    Map<String, String?>? query,
    Map<String, dynamic>? jsonBody,
    String httpMethod = 'post',
  }) async {
    log.finer('Calling function, url=$url');

    return _apiClient.request<http.Response>(
      httpMethod,
      url,
      query: query,
      jsonBody: jsonBody,
      headers: _session.authenticationHeaders,
    );
  }
}
