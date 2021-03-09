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

  Future<ResponseType> delete<ResponseType>(
    String path, {
    Map<String, String> headers,
    JsonDeserializer<ResponseType> responseDeserializer,
  }) async {
    return send<ResponseType>(
      _newApiRequest('delete', path),
      headers: headers,
      responseDeserializer: responseDeserializer,
    );
  }

  Future<ResponseType> get<ResponseType>(
    String path, {
    Map<String, String> headers,
    JsonDeserializer<ResponseType> responseDeserializer,
  }) async {
    return send<ResponseType>(
      _newApiRequest('get', path),
      headers: headers,
      responseDeserializer: responseDeserializer,
    );
  }

  Future<ResponseType> post<ResponseType>(
    String path, {
    Map<String, dynamic> data,
    Map<String, String> headers,
    JsonDeserializer<ResponseType> responseDeserializer,
  }) async {
    final request = _newApiRequest('post', path);
    if (data != null) {
      request
        ..body = jsonEncode(data)
        ..headers.addAll({
          HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
        });
    }

    return send<ResponseType>(
      request,
      headers: headers,
      responseDeserializer: responseDeserializer,
    );
  }

  Future<ResponseType> postMultipart<ResponseType>(
    String path, {
    Iterable<http.MultipartFile> files,
    Map<String, String> headers,
    JsonDeserializer<ResponseType> responseDeserializer,
  }) async {
    return send<ResponseType>(
      http.MultipartRequest('post', _baseUrl.extend(path))..files.addAll(files),
      headers: headers,
      responseDeserializer: responseDeserializer,
    );
  }

  Future<ResponseType> put<ResponseType>(
    String path, {
    Map<String, String> headers,
    JsonDeserializer<ResponseType> responseDeserializer,
  }) async {
    return send<ResponseType>(
      _newApiRequest('put', path),
      headers: headers,
      responseDeserializer: responseDeserializer,
    );
  }

  /// [data] is a JSON-serializable map
  Future<ResponseType> send<ResponseType>(
    http.BaseRequest request, {
    Map<String, String> headers,
    JsonDeserializer<ResponseType> responseDeserializer,
  }) async {
    if (headers != null) {
      request.headers.addAll(headers);
    }

    final response =
        await http.Response.fromStream(await _httpClient.send(request));
    final isJson = response.headers['content-type'] == _jsonContentType;
    dynamic responseBody = isJson ? jsonDecode(response.body) : response.body;

    // We group request and response together because the request's headers are
    // only guaranteed available after sending.
    if (debugPrintApiCalls) {
      debugPrint('\nREQUEST');
      debugPrint('${request.method} ${request.url}');
      debugPrint(request.headers.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n'));
      if (request is http.Request) {
        debugPrint(request.body);
      } else if (request is http.MultipartRequest) {
        debugPrint('files:');
        debugPrint(request.files.map((f) => '- ${f.filename}').join('\n'));
      }

      debugPrint('\nRESPONSE');
      debugPrint('${response.statusCode}');
      debugPrint(response.headers.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n'));
      if (isJson) {
        debugPrint(JsonEncoder.withIndent('  ').convert(responseBody));
      } else {
        debugPrint(responseBody);
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(request.url, responseBody, request, response);
    }

    if (responseDeserializer != null && isJson) {
      return responseDeserializer(responseBody);
    } else {
      return null;
    }
  }

  http.Request _newApiRequest(String method, String path) =>
      http.Request(method, _baseUrl.extend(path))..encoding = utf8;
}

class ApiException {
  ApiException(this.url, this.body, this.request, this.response);

  final Uri url;
  final dynamic body;
  final http.BaseRequest request;
  final http.Response response;

  dynamic get responseBody => body;
  int get statusCode => response.statusCode;

  @override
  String toString() {
    try {
      return 'ApiException('
          'apiUrl=$url, statusCode=$statusCode, responseBody=$responseBody)';
    } catch (e, st) {
      print('!!! $e\n$st');
      return '';
    }
  }
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

typedef JsonDeserializer<ResponseType> = ResponseType Function(dynamic json);

JsonDeserializer<List<ElementType>> listOf<ElementType>(
    JsonDeserializer<ElementType> deserializer) {
  return (dynamic json) {
    assert(json is List);
    if (json is List) {
      return json.map((elementJson) => deserializer(elementJson)).toList();
    }
    // TODO(shyndman): Revisit
    throw ArgumentError();
  };
}
