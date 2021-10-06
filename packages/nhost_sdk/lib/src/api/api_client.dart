import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:meta/meta.dart';
import 'package:nhost_sdk/src/logging.dart';

import '../foundation/uri.dart';
import '../http.dart';

/// Defined here so we don't need to import dart:io (which affects quality
/// score, because it thinks that dart:io makes using Flutter Web impossible)
final _noCharsetJsonContentType = MediaType('application', 'json');
final _jsonContentType =
    _noCharsetJsonContentType.change(parameters: {'charset': 'utf-8'});

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
    required http.Client httpClient,
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
  Future<ResponseType?> delete<ResponseType>(
    String path, {
    Map<String, String>? headers,
    JsonDeserializer<ResponseType>? responseDeserializer,
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
    Map<String, String>? headers,
    JsonDeserializer<ResponseType>? responseDeserializer,
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
    Map<String, String?> query = const {},
    Map<String, dynamic>? data,
    Map<String, String>? headers,
    JsonDeserializer<ResponseType>? responseDeserializer,
  }) async {
    final request = _newApiRequest('post', path, query: query);
    if (data != null) {
      request
        ..body = jsonEncode(data)
        ..headers.addAll({
          contentTypeHeader: _jsonContentType.toString(),
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
    required Iterable<http.MultipartFile> files,
    Map<String, String>? headers,
    JsonDeserializer<ResponseType>? responseDeserializer,
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
    Map<String, String>? headers,
    JsonDeserializer<ResponseType>? responseDeserializer,
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
    Map<String, String>? headers,
    JsonDeserializer<ResponseType>? responseDeserializer,
  }) async {
    if (headers != null) {
      request.headers.addAll(headers);
    }

    return _handleResponse(
      await http.Response.fromStream(await _httpClient.send(request)),
      responseDeserializer: responseDeserializer,
    );
  }

  http.Request _newApiRequest(
    String method,
    String path, {
    Map<String, String?>? query,
  }) =>
      http.Request(method, baseUrl.extend(path, queryParameters: query))
        ..encoding = utf8;

  ResponseType _handleResponse<ResponseType>(
    http.Response response, {
    JsonDeserializer<ResponseType>? responseDeserializer,
  }) {
    final request = response.request!;
    final contentTypeHeader = response.headers['content-type'];
    final isJson =
        contentTypeHeader?.startsWith(_noCharsetJsonContentType.toString()) ==
            true;
    dynamic responseBody = isJson ? jsonDecode(response.body) : response.body;

    // If the status is not in the success range, throw.
    if (response.statusCode < 200 || response.statusCode >= 300) {
      log.finer('API client encountered a failure, '
          'url=${request.url} status=${response.statusCode}');
      throw ApiException(request.url, responseBody, request, response);
    }

    // Deserialize the response if requested.
    if (ResponseType == http.Response) {
      return response as ResponseType;
    } else if (responseDeserializer != null) {
      return responseDeserializer(responseBody);
    } else {
      return null as ResponseType;
    }
  }
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
    if (json is List) {
      return json.map((elementJson) => deserializer(elementJson)).toList();
    }
    throw ArgumentError.value(
        json, 'json', 'List of $ElementType expected during deserialization');
  };
}
