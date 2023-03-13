import 'package:http/http.dart' as http;

abstract class FunctionsClient {
  Future<http.Response> callFunction(
    String url, {
    Map<String, String?>? query,
    Map<String, dynamic>? jsonBody,
    String httpMethod = 'post',
  });
}
