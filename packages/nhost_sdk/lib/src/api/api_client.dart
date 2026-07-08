import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:meta/meta.dart';

import '../errors.dart';
import '../foundation/collection.dart';
import '../foundation/request.dart';
import '../foundation/uri.dart';
import '../foundation/types.dart';
import '../http.dart';
import '../logging.dart';

/// Multipart request byte streams are chunked before sending so that we can
/// measure progress as the bytes are pulled by the socket. This is the size
/// of those chunks, in bytes.
const int multipartChunkSize = 64 * 1024; // 64 KB

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
    Map<String, String>? query,
    Map<String, String>? headers,
    JsonDeserializer<ResponseType>? responseDeserializer,
  }) async {
    query ??= const {};
    return send<ResponseType>(
      _newApiRequest('delete', path, query: query),
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
    Map<String, String>? query,
    Map<String, String>? headers,
    JsonDeserializer<ResponseType>? responseDeserializer,
  }) async {
    query ??= const {};
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
    Map<String, String?>? query,
    dynamic jsonBody,
    Map<String, String>? headers,
    JsonDeserializer<ResponseType>? responseDeserializer,
  }) async {
    query ??= const {};
    final req = _newApiRequest('post', path, query: query, jsonBody: jsonBody);
    return send<ResponseType>(
      req,
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
    Map<String, String>? fields,
    Map<String, String>? headers,
    JsonDeserializer<ResponseType>? responseDeserializer,
    UploadProgressCallback? onUploadProgress,
  }) async {
    final url = baseUrl.extend(path);
    final multipartRequest = http.MultipartRequest('post', url)
      ..files.addAll(files)
      ..fields.addAll(fields ?? {});

    http.BaseRequest requestToSend;
    if (onUploadProgress != null) {
      final chunkedByteStream = chunkStream(
        multipartRequest.finalize(),
        chunkLength: multipartChunkSize,
      );

      // Reporting upload progress isn't straightforward, so we have to jump
      // through a few hoops to get it going.
      //
      // The central idea is that we create the stream representation of the
      // request, set ourselves up to watch the stream's consumption rate, then
      // send it over the wire. The consumed bytes are reported to the callback
      // as the upload progress.
      var bytesUploaded = 0;
      final bytesTotal = multipartRequest.contentLength;
      final observedByteStream = chunkedByteStream
          .transform(StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (data, sink) {
          // Pass the data along the chain
          sink.add(data);

          // ...and report progress
          bytesUploaded += data.length;
          onUploadProgress(multipartRequest, bytesUploaded, bytesTotal);
        },
        handleError: (error, stackTrace, sink) =>
            throw AsyncError(error, stackTrace),
        handleDone: (sink) => sink.close(),
      ));

      requestToSend = StreamWrappingRequest('post', url, observedByteStream)
        ..contentLength = multipartRequest.contentLength
        ..headers.addAll(multipartRequest.headers);
    } else {
      requestToSend = multipartRequest;
    }

    return send<ResponseType>(
      requestToSend,
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
    Map<String, String?>? query,
    dynamic jsonBody,
    Map<String, String>? headers,
    JsonDeserializer<ResponseType>? responseDeserializer,
  }) async {
    query ??= const {};
    return send<ResponseType>(
      _newApiRequest('put', path, query: query, jsonBody: jsonBody),
      headers: headers,
      responseDeserializer: responseDeserializer,
    );
  }

  /// Performs an HTTP PUT multipart api call.
  ///
  /// {@macro nhost.api.ApiClient.path}
  ///
  /// {@macro nhost.api.ApiClient.responseDeserializer}
  Future<ResponseType> putMultipart<ResponseType>(
    String path, {
    required Iterable<http.MultipartFile> files,
    Map<String, String>? fields,
    Map<String, String>? headers,
    JsonDeserializer<ResponseType>? responseDeserializer,
    UploadProgressCallback? onUploadProgress,
  }) async {
    final url = baseUrl.extend(path);
    final multipartRequest = http.MultipartRequest('put', url)
      ..files.addAll(files)
      ..fields.addAll(fields ?? {});

    http.BaseRequest requestToSend;
    if (onUploadProgress != null) {
      final chunkedByteStream = chunkStream(
        multipartRequest.finalize(),
        chunkLength: multipartChunkSize,
      );

      // Reporting upload progress isn't straightforward, so we have to jump
      // through a few hoops to get it going.
      //
      // The central idea is that we create the stream representation of the
      // request, set ourselves up to watch the stream's consumption rate, then
      // send it over the wire. The consumed bytes are reported to the callback
      // as the upload progress.
      var bytesUploaded = 0;
      final bytesTotal = multipartRequest.contentLength;
      final observedByteStream = chunkedByteStream
          .transform(StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (data, sink) {
          // Pass the data along the chain
          sink.add(data);

          // ...and report progress
          bytesUploaded += data.length;
          onUploadProgress(multipartRequest, bytesUploaded, bytesTotal);
        },
        handleError: (error, stackTrace, sink) =>
            throw AsyncError(error, stackTrace),
        handleDone: (sink) => sink.close(),
      ));

      requestToSend = StreamWrappingRequest('put', url, observedByteStream)
        ..contentLength = multipartRequest.contentLength
        ..headers.addAll(multipartRequest.headers);
    } else {
      requestToSend = multipartRequest;
    }

    return send<ResponseType>(
      requestToSend,
      headers: headers,
      responseDeserializer: responseDeserializer,
    );
  }

  /// Performs an HTTP request of the specified method.
  Future<ResponseType> request<ResponseType>(
    String method,
    String path, {
    Map<String, String?>? query,
    dynamic jsonBody,
    Map<String, String>? headers,
    JsonDeserializer<ResponseType>? responseDeserializer,
  }) async {
    query ??= const {};
    return send<ResponseType>(
      _newApiRequest(method, path, query: query, jsonBody: jsonBody),
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

    log.finest(() =>
        'Sending a ${request.method.toUpperCase()} request to ${request.url}');

    try {
      return _handleResponse<ResponseType>(
        request,
        await http.Response.fromStream(await _httpClient.send(request)),
        responseDeserializer: responseDeserializer,
      );
    } on NhostException {
      rethrow;
    } catch (e, st) {
      // Wrap raw network-layer failures (SocketException, TimeoutException,
      // etc.) so callers have a single Nhost type hierarchy to catch.
      throw NhostNetworkException(cause: e, causeStackTrace: st);
    }
  }

  http.Request _newApiRequest(
    String method,
    String path, {
    Map<String, String?>? query,
    dynamic jsonBody,
  }) {
    final req = http.Request(
      method,
      baseUrl.extend(path, queryParameters: query),
    )..encoding = utf8;
    if (jsonBody != null) {
      req
        ..body = jsonEncode(jsonBody)
        ..headers.addAll({
          contentTypeHeader: _jsonContentType.toString(),
        });
    }
    return req;
  }

  ResponseType _handleResponse<ResponseType>(
    http.BaseRequest request,
    http.Response response, {
    JsonDeserializer<ResponseType>? responseDeserializer,
  }) {
    final contentTypeHeader = response.headers['content-type'];
    final isJson =
        contentTypeHeader?.startsWith(_noCharsetJsonContentType.toString()) ==
            true;
    dynamic responseBody = isJson ? jsonDecode(response.body) : response.body;

    // If the status is not in the success range,  throw.
    if (response.statusCode < 200 || response.statusCode >= 300) {
      log.finer(
        'API client encountered a failure, '
        'url=${request.url} status=${response.statusCode}',
      );
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
///
/// Nhost error bodies follow a consistent shape:
/// `{"error": "invalid-request", "message": "...", "status": 400}`
///
/// Use [errorCode] and [errorMessage] to access those fields without casting
/// the raw [responseBody]. Use the convenience booleans for common checks:
///
/// ```dart
/// } on ApiException catch (e) {
///   if (e.isUnauthorized) { ... }
///   print(e.errorMessage); // "Invalid email or password"
/// }
/// ```
class ApiException extends NhostException {
  ApiException(this.url, this.body, this.request, this.response);

  final Uri url;
  final dynamic body;
  final http.BaseRequest request;
  final http.Response response;

  dynamic get responseBody => body;
  int get statusCode => response.statusCode;

  /// Nhost error code from the response body, e.g. `"invalid-request"`,
  /// `"email-already-in-use"`. `null` if the body is not a JSON object.
  String? get errorCode => body is Map ? body['error'] as String? : null;

  /// Human-readable error message from the response body.
  /// `null` if the body is not a JSON object.
  String? get errorMessage => body is Map ? body['message'] as String? : null;

  /// `true` when [statusCode] is 401 — credentials missing or expired.
  bool get isUnauthorized => statusCode == 401;

  /// `true` when [statusCode] is 403 — authenticated but access denied.
  bool get isForbidden => statusCode == 403;

  /// `true` when [statusCode] is 404 — resource not found.
  bool get isNotFound => statusCode == 404;

  /// `true` when [statusCode] is 400 or 422 — request body failed validation.
  bool get isValidationError => statusCode == 400 || statusCode == 422;

  /// `true` when [statusCode] is 5xx — server-side failure.
  bool get isServerError => statusCode >= 500;

  @override
  String toString() {
    final extra = errorCode != null ? ' errorCode=$errorCode' : '';
    return 'ApiException: '
        'apiUrl=$url, statusCode=$statusCode$extra, responseBody=$responseBody';
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
