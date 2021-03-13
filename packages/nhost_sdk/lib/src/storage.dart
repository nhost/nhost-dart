import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:meta/meta.dart';
import 'package:nhost_dart_sdk/src/api/storage_api_types.dart';

import 'api/api_client.dart';
import 'foundation/uri.dart';
import 'session.dart';

/// The Nhost storage service.
///
/// Supports the storage and retrieval of files on the backend.
///
/// See https://docs.nhost.io/storage/api-reference for more info.
class Storage {
  final ApiClient _apiClient;
  final UserSession _session;

  Storage({
    @required String baseUrl,
    @required UserSession session,
    http.Client httpClient,
  })  : _apiClient = ApiClient(Uri.parse(baseUrl), httpClient: httpClient),
        _session = session;

  /// Releases the object's resources.
  void close() {
    _apiClient?.close();
  }

  /// Uploads a file to the backend from a list of bytes.
  ///
  /// Throws an [ApiException] if the upload fails.
  ///
  /// https://docs.nhost.io/storage/api-reference#upload-file
  Future<FileMetadata> putFileFromBytes({
    @required String filePath,
    @required List<int> bytes,
    String contentType,
    Function onUploadProgress,
  }) async {
    final file = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filePath,
      contentType: MediaType.parse(contentType),
    );

    return await _apiClient.postMultipart<FileMetadata>(
      joinSubpath('/o', filePath),
      headers: _session.authenticationHeaders,
      files: [file],
      responseDeserializer: FileMetadata.fromJson,
    );
  }

  /// Uploads a file to the backend from a string.
  ///
  /// Throws an [ApiException] if the upload fails.
  ///
  /// https://docs.nhost.io/storage/api-reference#upload-file
  Future<FileMetadata> putFileFromString({
    @required String filePath,
    @required String data,
    String contentType,
    Function onUploadProgress,
  }) async {
    final file = http.MultipartFile.fromString(
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
        ..._session.authenticationHeaders,
      },
      // onUploadProgress,
      responseDeserializer: FileMetadata.fromJson,
    );
  }

  /// Deletes a file on the backend.
  ///
  /// Throws an [ApiException] if the deletion fails.
  ///
  /// https://docs.nhost.io/storage/api-reference#delete-file
  Future<void> delete(String filePath) async {
    await _apiClient.delete(
      joinSubpath('/o', filePath),
      headers: _session.authenticationHeaders,
    );
  }

  /// Retrieves a file's metadata from the backend.
  ///
  /// Throws an [ApiException] if the metadata retrieval fails.
  ///
  /// https://docs.nhost.io/storage/api-reference#get-file-metadata
  Future<FileMetadata> getFileMetadata(String filePath) async {
    assert(!filePath.endsWith('/'),
        '$filePath is not a valid file path, because it ends with a /');
    return await _apiClient.get(
      joinSubpath('/m', filePath),
      headers: _session.authenticationHeaders,
      responseDeserializer: FileMetadata.fromJson,
    );
  }

  /// Retrieves a directory's contents' metadata from the backend.
  ///
  /// Throws an [ApiException] if the metadata retrieval fails.
  ///
  /// https://docs.nhost.io/storage/api-reference#get-directory-metadata
  Future<List<FileMetadata>> getDirectoryMetadata(String directoryPath) async {
    assert(
        directoryPath.endsWith('/'),
        '$directoryPath is not a valid directory path, because it does not '
        'end with a /');
    return await _apiClient.get(
      joinSubpath('/m', directoryPath),
      headers: _session.authenticationHeaders,
      responseDeserializer: listOf(FileMetadata.fromJson),
    );
  }
}
