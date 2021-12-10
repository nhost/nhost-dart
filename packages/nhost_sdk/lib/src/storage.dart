import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:nhost_sdk/src/api/storage_api_types.dart';

import 'api/api_client.dart';
import 'foundation/uri.dart';
import 'session.dart';

/// The default used during file upload if not provided.
const applicationOctetStreamType = 'application/octet-stream';

/// The Nhost storage service.
///
/// Supports the storage and retrieval of files on the backend.
class Storage {
  final ApiClient _apiClient;
  final UserSession _session;

  Storage({
    required String baseUrl,
    required UserSession session,
    required http.Client httpClient,
  })  : _apiClient = ApiClient(Uri.parse(baseUrl), httpClient: httpClient),
        _session = session;

  /// Releases the object's resources.
  void close() {
    _apiClient.close();
  }

  /// Uploads a file to the backend from a list of bytes.
  ///
  /// If not provided, [contentType] defaults to `application/octet-stream`.
  ///
  /// Throws an [ApiException] if the upload fails.
  Future<FileMetadata> uploadBytes({
    required String filePath,
    required List<int> bytes,
    String contentType = applicationOctetStreamType,
    UploadProgressCallback? onUploadProgress,
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
      onUploadProgress: onUploadProgress,
    );
  }

  /// Uploads a file to the backend from a string.
  ///
  /// If not provided, [contentType] defaults to `application/octet-stream`.
  ///
  /// Throws an [ApiException] if the upload fails.
  Future<FileMetadata> uploadString({
    required String filePath,
    required String string,
    String contentType = applicationOctetStreamType,
    UploadProgressCallback? onUploadProgress,
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
        ..._session.authenticationHeaders,
      },
      responseDeserializer: FileMetadata.fromJson,
      onUploadProgress: onUploadProgress,
    );
  }

  /// Downloads the file at the provided path.
  ///
  /// {@template nhost.api.Storage.fileToken}
  /// The [fileToken] argument must be provided if the resource is protected
  /// by a storage function that checks the file's `resource.Metadata.token`
  /// (https://nhost.github.io/hasura-backend-plus/docs/storage-rules).
  /// {@endtemplate}
  ///
  /// The file is returned as an HTTP response, populated with the headers.
  Future<http.Response> downloadFile(String filePath, {String? fileToken}) {
    return _apiClient.get<http.Response>(
      _objectPath(filePath),
      query: {
        if (fileToken != null) 'token': fileToken,
      },
      headers: _session.authenticationHeaders,
    );
  }

  /// Downloads the image at the provided path, transforming it if requested.
  ///
  /// {@macro nhost.api.Storage.fileToken}
  ///
  /// [imageTransformConfig] (optional) instructs the backend to scale or adjust the
  /// quality of the returned image.
  ///
  /// The file is returned as an HTTP response, populated with the headers.
  Future<http.Response?> downloadImage(
    String filePath, {
    String? fileToken,
    ImageTransformConfig? imageTransformConfig,
  }) {
    return _apiClient.get<http.Response>(
      _objectPath(filePath),
      query: {
        if (fileToken != null) 'token': fileToken,
        ...?imageTransformConfig?.toQueryArguments(),
      },
      headers: _session.authenticationHeaders,
    );
  }

  /// Deletes a file on the backend.
  ///
  /// Throws an [ApiException] if the deletion fails.
  Future<void> delete(String filePath) async {
    await _apiClient.delete(
      _objectPath(filePath),
      headers: _session.authenticationHeaders,
    );
  }

  /// Retrieves a file's metadata from the backend.
  ///
  /// {@macro nhost.api.Storage.fileToken}
  ///
  /// Throws an [ApiException] if the metadata retrieval fails.
  Future<FileMetadata> getFileMetadata(
    String filePath, {
    String? fileToken,
  }) async {
    assert(!filePath.endsWith('/'),
        '$filePath is not a valid file path, because it ends with a /');
    return await _apiClient.get(
      _metadataPath(filePath),
      query: {
        if (fileToken != null) 'token': fileToken,
      },
      headers: _session.authenticationHeaders,
      responseDeserializer: FileMetadata.fromJson,
    );
  }

  /// Retrieves a directory's contents' metadata from the backend.
  ///
  /// Throws an [ApiException] if the metadata retrieval fails.
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
