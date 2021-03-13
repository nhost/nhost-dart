import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:nhost_dart_sdk/src/debug.dart';

import '../foundation/uri.dart';

final _jsonContentType = ContentType.json.toString();

/// Provides HTTP API methods, with response deserialization.
///
/// This client is built to resemble Node's Axios package
/// (https://github.com/axios/axios) by:
///
/// * throwing exceptions if response status codes fall outside of the 2xx range
/// * automatically encoding request bodies as JSON
class ApiClient {
  /// All HTTP methods ([get], [post], etc.) append their path args to [baseUrl]
  /// in order to build the endpoint URL.
  ///
  /// An optional [httpClient] can be provided if a custom HTTP strategy is
  /// required, as is the case with proxies.
  ApiClient(
    this.baseUrl, {
    @required http.Client httpClient,
  }) : _httpClient = httpClient;

  final Uri baseUrl;
  final http.Client _httpClient;

  /// Closes the API client.
  ///
  /// Any requests made after closing the client will fail.
  void close() {
    try {
      _httpClient.close();
    } catch (_) {}
  }

  /// Performs an HTTP DELETE api call.
  ///
  /// {@template nhost.api.ApiClient.path}
  /// [path] is appended to [baseUrl] to determine the API endpoint.
  /// {@endtemplate}
  ///
  /// {@template nhost.api.ApiClient.responseDeserializer}
  /// The return value is the result of passing the response's JSON-decoded body
  /// to [responseDeserializer]. If [responseDeserializer] is `null`, `null`
  /// will be returned.
  /// {@endtemplate}
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

  /// Performs an HTTP GET api call.
  ///
  /// {@macro nhost.api.ApiClient.path}
  ///
  /// {@macro nhost.api.ApiClient.responseDeserializer}
  Future<ResponseType> get<ResponseType>(
    String path, {
    Map<String, String> query = const {},
    Map<String, String> headers,
    JsonDeserializer<ResponseType> responseDeserializer,
  }) async {
    return send<ResponseType>(
      _newApiRequest('get', path, query: query),
      headers: headers,
      responseDeserializer: responseDeserializer,
    );
  }

  /// Performs an HTTP POST api call.
  ///
  /// {@macro nhost.api.ApiClient.path}
  ///
  /// {@macro nhost.api.ApiClient.responseDeserializer}
  Future<ResponseType> post<ResponseType>(
    String path, {
    Map<String, String> query = const {},
    Map<String, dynamic> data,
    Map<String, String> headers,
    JsonDeserializer<ResponseType> responseDeserializer,
  }) async {
    final request = _newApiRequest('post', path, query: query);
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

  /// Performs an HTTP POST multipart api call.
  ///
  /// {@macro nhost.api.ApiClient.path}
  ///
  /// {@macro nhost.api.ApiClient.responseDeserializer}
  Future<ResponseType> postMultipart<ResponseType>(
    String path, {
    Iterable<http.MultipartFile> files,
    Map<String, String> headers,
    JsonDeserializer<ResponseType> responseDeserializer,
  }) async {
    return send<ResponseType>(
      http.MultipartRequest('post', baseUrl.extend(path))..files.addAll(files),
      headers: headers,
      responseDeserializer: responseDeserializer,
    );
  }

  /// Performs an HTTP PUT api call.
  ///
  /// {@macro nhost.api.ApiClient.path}
  ///
  /// {@macro nhost.api.ApiClient.responseDeserializer}
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

  @protected
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

    if (ResponseType == http.Response) {
      return response as ResponseType;
    } else if (responseDeserializer != null) {
      return responseDeserializer(responseBody);
    } else {
      return null;
    }
  }

  http.Request _newApiRequest(
    String method,
    String path, {
    Map<String, String> query,
  }) =>
      http.Request(method, baseUrl.extend(path, queryParameters: query))
        ..encoding = utf8;
}

/// Thrown by [ApiClient] to indicate a failed API call.
///
/// An API call is considered failed if its [response]'s [statusCode] falls
/// outside the 2xx range.
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
    return 'ApiException('
        'apiUrl=$url, statusCode=$statusCode, responseBody=$responseBody)';
  }
}

/// Maps a JSON-decoded [json] value into a [ResponseType].
typedef JsonDeserializer<ResponseType> = ResponseType Function(dynamic json);

/// Maps a JSON-decoded list of elements into a list of [ElementType].
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
