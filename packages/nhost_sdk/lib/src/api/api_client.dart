import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http;
import 'package:nhost_dart_sdk/src/debug.dart';

import '../foundation/uri.dart';

final _jsonContentType = ContentType.json.toString();

/// Provides HTTP API methods, with response deserialization.
///
/// This client is built to resemble Node's Axios package
/// (https://github.com/axios/axios) in the following ways:
///
/// * throws exceptions if response status codes fall outside of the 2xx range
/// * automatically encodes request bodies as JSON
class ApiClient {
  ApiClient(Uri baseUrl)
      : _baseUrl = baseUrl,
        _httpClient = _createHttpClient();

  final http.Client _httpClient;
  final Uri _baseUrl;

  Future<ResponseType> get<ResponseType>(
    String path, {
    Map<String, String> headers,
    ResponseType Function(Map<String, dynamic>) responseDeserializer,
  }) async {
    return send<ResponseType>(
      'get',
      path,
      headers: headers,
      responseDeserializer: responseDeserializer,
    );
  }

  /// [data] is a JSON-serializable map
  Future<ResponseType> post<ResponseType>(
    String path, {
    Map<String, dynamic> data,
    Map<String, String> headers,
    ResponseType Function(Map<String, dynamic>) responseDeserializer,
  }) async {
    return send<ResponseType>(
      'post',
      path,
      data: data,
      headers: headers,
      responseDeserializer: responseDeserializer,
    );
  }

  /// [data] is a JSON-serializable map
  Future<ResponseType> send<ResponseType>(
    String method,
    String path, {
    Map<String, dynamic> data,
    Map<String, String> headers,
    ResponseType Function(Map<String, dynamic>) responseDeserializer,
  }) async {
    final apiUrl = _baseUrl.extend(path);

    final request = http.Request(method, apiUrl)
      ..encoding = utf8
      ..headers.addAll({...?headers});

    if (data != null) {
      request
        ..body = jsonEncode(data)
        ..headers.addAll({
          if (request.headers.containsKey(HttpHeaders.contentTypeHeader))
            HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
        });
    }

    if (debugPrintApiCalls) {
      debugPrint('\nREQUEST');
      debugPrint('${request.method} $apiUrl');
      debugPrint(request.headers.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n'));
      debugPrint(request.body);
    }

    final response =
        await http.Response.fromStream(await _httpClient.send(request));
    final isJson = response.headers['content-type'] == _jsonContentType;

    dynamic body = isJson ? jsonDecode(response.body) : response.body;

    if (debugPrintApiCalls) {
      debugPrint('\nRESPONSE');
      debugPrint('${response.statusCode}');
      debugPrint(response.headers.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n'));
      if (isJson) {
        debugPrint(JsonEncoder.withIndent('  ').convert(body));
      } else {
        debugPrint(body);
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(apiUrl, body, request, response);
    }

    if (responseDeserializer != null && isJson) {
      assert(body is Map<String, dynamic>,
          'Response body for $apiUrl is expected to be a JSON map');
      return responseDeserializer(body as Map<String, dynamic>);
    } else {
      return null;
    }
  }
}

class ApiException {
  ApiException(this.url, this.body, this.request, this.response);

  final Uri url;
  final dynamic body;
  final http.Request request;
  final http.Response response;

  String get responseBody => body;
  int get statusCode => response.statusCode;

  @override
  String toString() => 'ApiException('
      'apiUrl=$url, statusCode=$statusCode, responseBody=$responseBody)';
}

http.Client _createHttpClient() {
  final innerClient = HttpClient();
  // innerClient.findProxy = HttpClient.findProxyFromEnvironment;
  // innerClient.badCertificateCallback = (cert, host, port) {
  //   print('bad cert $host');
  //   return true;
  // };
  return http.IOClient(innerClient);
}
