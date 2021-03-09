import 'dart:io';

import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:meta/meta.dart';
import 'package:nhost_dart_sdk/src/api/storage_api.dart';

import 'api/api_client.dart';
import 'foundation/uri.dart';
import 'session.dart';

class Storage {
  final ApiClient _apiClient;
  final UserSession _currentSession;

  Storage({
    @required String baseUrl,
    @required UserSession session,
    HttpClient httpClient,
  })  : _apiClient = ApiClient(Uri.parse(baseUrl), httpClient: httpClient),
        _currentSession = session;

  /// Releases the object's resources.
  void close() {
    _apiClient?.close();
  }

  Future<FileMetadata> putFileFromBytes({
    @required String filePath,
    @required List<int> bytes,
    String contentType,
    Function onUploadProgress,
  }) async {
    final file = MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filePath,
      contentType: MediaType.parse(contentType),
    );

    return await _apiClient.postMultipart<FileMetadata>(
      joinSubpath('/o', filePath),
      headers: _generateHeaders(),
      files: [file],
      responseDeserializer: FileMetadata.fromJson,
    );
  }

  Future<FileMetadata> putFileFromString({
    @required String filePath,
    @required String data,
    String contentType,
    Function onUploadProgress,
  }) async {
    final file = MultipartFile.fromString(
      'file',
      data,
      filename: filePath,
      contentType: MediaType.parse(contentType),
    );

    return await _apiClient.postMultipart(
      joinSubpath('/o', filePath),
      files: [file],
      headers: {
        'Content-Type': 'multipart/form-data',
        ..._generateHeaders(),
      },
      // onUploadProgress,
      responseDeserializer: FileMetadata.fromJson,
    );
  }

  void delete(String filePath) async {
    await _apiClient.delete(
      joinSubpath('/o', filePath),
      headers: _generateHeaders(),
    );
  }

  Future<FileMetadata> getFileMetadata(String filePath) async {
    assert(!filePath.endsWith('/'),
        '$filePath is not a valid file path, because it ends with a /');
    return await _apiClient.get(
      joinSubpath('/m', filePath),
      headers: _generateHeaders(),
      responseDeserializer: FileMetadata.fromJson,
    );
  }

  Future<List<FileMetadata>> getDirectoryMetadata(String directoryPath) async {
    assert(
        directoryPath.endsWith('/'),
        '$directoryPath is not a valid directory path, because it does not '
        'end with a /');
    return await _apiClient.get(
      joinSubpath('/m', directoryPath),
      headers: _generateHeaders(),
      responseDeserializer: listOf(FileMetadata.fromJson),
    );
  }

  Map<String, String> _generateHeaders() {
    return {
      if (_currentSession.session != null)
        HttpHeaders.authorizationHeader:
            'Bearer ${_currentSession.session?.jwtToken}',
    };
  }
}
