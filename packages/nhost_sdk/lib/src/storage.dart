import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:nhost_sdk/src/api/storage_api_types.dart';

import 'api/api_client.dart';
import 'session.dart';

/// The default used during file upload if not provided.
const applicationOctetStreamType = 'application/octet-stream';

/// The Nhost storage service.
///
/// Supports the storage and retrieval of files on the backend.
class StorageClient {
  final ApiClient _apiClient;
  final UserSession _session;

  StorageClient({
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
  /// If not provided, [mimeType] defaults to `application/octet-stream`.
  ///
  /// Throws an [ApiException] if the upload fails.
  Future<FileMetadata> uploadBytes({
    required String fileName,
    required List<int> fileContents,
    String? fileId,
    String? bucketId,
    String mimeType = applicationOctetStreamType,
    UploadProgressCallback? onUploadProgress,
  }) async {
    return await _uploadMultipartFile(
      file: http.MultipartFile.fromBytes(
        'file',
        fileContents,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
      fileName: fileName,
      fileId: fileId,
      bucketId: bucketId,
      onUploadProgress: onUploadProgress,
    );
  }

  /// Uploads a file to the backend from a string.
  ///
  /// If not provided, [mimeType] defaults to `application/octet-stream`.
  ///
  /// Throws an [ApiException] if the upload fails.
  Future<FileMetadata> uploadString({
    required String fileName,
    required String fileContents,
    String? fileId,
    String? bucketId,
    String mimeType = applicationOctetStreamType,
    UploadProgressCallback? onUploadProgress,
  }) async {
    return await _uploadMultipartFile(
      file: http.MultipartFile.fromString(
        'file',
        fileContents,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
      fileId: fileId,
      fileName: fileName,
      bucketId: bucketId,
      onUploadProgress: onUploadProgress,
    );
  }

  Future<FileMetadata> _uploadMultipartFile({
    required http.MultipartFile file,
    String? fileName,
    String? fileId,
    String? bucketId,
    UploadProgressCallback? onUploadProgress,
  }) async {
    return await _apiClient.postMultipart(
      '/files',
      files: [file],
      headers: {
        ..._session.authenticationHeaders,
        if (bucketId != null) 'x-nhost-bucket-id': bucketId,
        if (fileId != null) 'x-nhost-file-id': fileId,
        if (fileName != null) 'x-nhost-file-name': fileName,
      },
      responseDeserializer: FileMetadata.fromJson,
      onUploadProgress: onUploadProgress,
    );
  }

  /// Downloads the file with the specified identifier.
  Future<http.Response> downloadFile(String fileId) async {
    return _apiClient.get<http.Response>(
      '/files/$fileId',
      headers: _session.authenticationHeaders,
    );
  }

  /// Downloads the image with the specified identifier, optionally applying
  /// a visual transformation.
  Future<http.Response> downloadImage(
    String fileId, {
    ImageTransform? transform,
  }) async {
    return _apiClient.get<http.Response>(
      '/files/$fileId',
      query: {
        ...?transform?.toQueryArguments(),
      },
      headers: _session.authenticationHeaders,
    );
  }

  Future<PresignedUrl> getPresignedUrl(String fileId) async {
    return await _apiClient.get(
      '/files/$fileId/presignedurl',
      headers: _session.authenticationHeaders,
      responseDeserializer: PresignedUrl.fromJson,
    );
  }

  /// Deletes a file on the backend.
  ///
  /// Throws an [ApiException] if the deletion fails.
  Future<void> delete(String fileId) async {
    await _apiClient.delete(
      '/files/$fileId',
      headers: _session.authenticationHeaders,
    );
  }
}
