import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:meta/meta.dart';
import 'package:nhost_dart_sdk/src/api/storage_api_types.dart';

import 'api/api_client.dart';
import 'foundation/uri.dart';
import 'session.dart';

/// The default used during file upload if not provided.
const applicationOctetStreamType = 'application/octet-stream';

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
  /// If not provided, [contentType] defaults to `application/octet-stream`.
  ///
  /// Throws an [ApiException] if the upload fails.
  ///
  /// https://docs.nhost.io/storage/api-reference#upload-file
  Future<FileMetadata> uploadBytes({
    @required String filePath,
    @required List<int> bytes,
    String contentType = applicationOctetStreamType,
  }) async {
    final file = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filePath,
      contentType: MediaType.parse(contentType),
    );

    return await _apiClient.postMultipart<FileMetadata>(
      _objectPath(filePath),
      headers: _session.authenticationHeaders,
      files: [file],
      responseDeserializer: FileMetadata.fromJson,
    );
  }

  /// Uploads a file to the backend from a string.
  ///
  /// If not provided, [contentType] defaults to `application/octet-stream`.
  ///
  /// Throws an [ApiException] if the upload fails.
  ///
  /// https://docs.nhost.io/storage/api-reference#upload-file
  Future<FileMetadata> uploadString({
    @required String filePath,
    @required String string,
    String contentType = applicationOctetStreamType,
  }) async {
    final file = http.MultipartFile.fromString(
      'file',
      string,
      filename: filePath,
      contentType: MediaType.parse(contentType),
    );

    return await _apiClient.postMultipart(
      _objectPath(filePath),
      files: [file],
      headers: {
        'Content-Type': 'multipart/form-data',
        ..._session.authenticationHeaders,
      },
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
      _objectPath(filePath),
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
      _metadataPath(filePath),
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
      _metadataPath(directoryPath),
      headers: _session.authenticationHeaders,
      responseDeserializer: listOf(FileMetadata.fromJson),
    );
  }

  String _objectPath(String filePath) => joinSubpath('/o', filePath);
  String _metadataPath(String filePath) => joinSubpath('/m', filePath);
}
