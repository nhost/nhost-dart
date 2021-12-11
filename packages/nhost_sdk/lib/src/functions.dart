import 'package:http/http.dart' as http;

import 'api/api_client.dart';
import 'logging.dart';
import 'session.dart';

/// The Nhost serverless function service.
///
/// See https://docs.nhost.io/platform/serverless-functions for more info.
class Functions {
  final ApiClient _apiClient;
  final UserSession _session;

  Functions({
    required String baseUrl,
    required UserSession session,
    required http.Client httpClient,
  })  : _apiClient = ApiClient(Uri.parse(baseUrl), httpClient: httpClient),
        _session = session;

  /// Invokes the serverless function at [url].
  ///
  /// The serverless function is invoked using an HTTP POST, so both a request
  /// body and query variables can be provided.
  ///
  /// Throws an [ApiException] if a failure occurs.
  Future<http.Response> invoke(
    String url, {
    Map<String, String?>? query,
    Map<String, dynamic>? jsonBody,
  }) async {
    log.finer('Calling function, url=$url');

    return _apiClient.post<http.Response>(
      url,
      query: query,
      jsonBody: jsonBody,
      headers: _session.authenticationHeaders,
    );
  }
}
