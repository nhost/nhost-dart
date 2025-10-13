import 'dart:convert';
import 'dart:typed_data';

import 'package:http_parser/http_parser.dart';
import 'package:nhost_sdk/nhost_sdk.dart';
import 'package:http/http.dart' as http;
import 'api/storage_api_types.dart';

/// The default used during file upload if not provided.
const applicationOctetStreamType = 'application/octet-stream; charset=utf-8';

/// The Nhost storage service.
///
/// Supports the storage and retrieval of files on the backend.
class NhostStorageClient implements HasuraStorageClient {
  /// {@macro nhost.api.NhostClient.subdomain}
  ///
  /// {@macro nhost.api.NhostClient.serviceUrls}
  ///
  /// {@macro nhost.api.NhostClient.httpClientOverride}
  NhostStorageClient({
    required String url,
    UserSession? session,
    http.Client? httpClient,
  })  : _apiClient = ApiClient(
          Uri.parse(url),
          httpClient: httpClient ?? http.Client(),
        ),
        _session = session ?? UserSession();

  final ApiClient _apiClient;
  final UserSession _session;

  /// Releases the object's resources.
  @override
  void close() {
    _apiClient.close();
  }

  /// Uploads a file to the backend from a list of bytes.
  ///
  /// If not provided, [mimeType] defaults to `application/octet-stream`.
  ///
  /// Throws an [ApiException] if the upload fails.
  ///
  /// **Deprecated**: Use [uploadFiles] instead for better flexibility and batch upload support.
  @Deprecated('Use uploadFiles instead for better flexibility and batch upload support')
  @override
  Future<FileMetadata> uploadBytes({
    required String fileName,
    required List<int> fileContents,
    String? fileId,
    String? bucketId,
    String mimeType = applicationOctetStreamType,
    Map<String, dynamic>? metadata,
    UploadProgressCallback? onUploadProgress,
  }) async {
    final fileData = FileData(
      Uint8List.fromList(fileContents),
      filename: fileName,
      contentType: mimeType,
    );

    final uploadMetadata = (fileId != null || metadata != null)
        ? UploadFileMetadata(id: fileId, name: fileName, metadata: metadata)
        : null;

    final results = await uploadFiles(
      files: [fileData],
      bucketId: bucketId,
      metadataList: uploadMetadata != null ? [uploadMetadata] : null,
      onUploadProgress: onUploadProgress,
    );

    return results.first;
  }

  /// Uploads a file to the backend from a string.
  ///
  /// If not provided, [mimeType] defaults to `application/octet-stream`.
  ///
  /// Throws an [ApiException] if the upload fails.
  ///
  /// **Deprecated**: Use [uploadFiles] instead for better flexibility and batch upload support.
  @Deprecated('Use uploadFiles instead for better flexibility and batch upload support')
  @override
  Future<FileMetadata> uploadString({
    required String fileName,
    required String fileContents,
    String? fileId,
    String? bucketId,
    String mimeType = applicationOctetStreamType,
    Map<String, dynamic>? metadata,
    UploadProgressCallback? onUploadProgress,
  }) async {
    final fileData = FileData(
      Uint8List.fromList(utf8.encode(fileContents)),
      filename: fileName,
      contentType: mimeType,
    );

    final uploadMetadata = (fileId != null || metadata != null)
        ? UploadFileMetadata(id: fileId, name: fileName, metadata: metadata)
        : null;

    final results = await uploadFiles(
      files: [fileData],
      bucketId: bucketId,
      metadataList: uploadMetadata != null ? [uploadMetadata] : null,
      onUploadProgress: onUploadProgress,
    );

    return results.first;
  }

  /// Uploads files to the backend matching the TypeScript API.
  ///
  /// This method closely mirrors the TypeScript `uploadFiles` API, providing
  /// a more flexible interface for file uploads.
  ///
  /// [files] is a list of FileData objects to upload.
  /// [metadataList] is an optional list of metadata for each file. If provided,
  /// must match the order and length of [files].
  /// [bucketId] specifies the target bucket for the upload.
  ///
  /// Returns a list of [FileMetadata] for the successfully uploaded files.
  ///
  /// Throws an [ApiException] if the upload fails.
  Future<List<FileMetadata>> uploadFiles({
    required List<FileData> files,
    String? bucketId,
    List<UploadFileMetadata>? metadataList,
    UploadProgressCallback? onUploadProgress,
  }) async {
    if (metadataList != null && metadataList.length != files.length) {
      throw ArgumentError(
        'metadataList length (${metadataList.length}) must match files length (${files.length})',
      );
    }

    final fields = <String, String>{};
    final multipartFiles = <http.MultipartFile>[];

    // Add bucket-id if present
    if (bucketId != null) {
      fields['bucket-id'] = bucketId;
    }

    // Add metadata[] if present
    if (metadataList != null) {
      for (final metadata in metadataList) {
        multipartFiles.add(
          http.MultipartFile.fromBytes(
            'metadata[]',
            utf8.encode(jsonEncode(metadata.toJson())),
            filename: '',
            contentType: MediaType('application', 'json'),
          ),
        );
      }
    }

    // Add file[] if present
    for (final file in files) {
      multipartFiles.add(
        http.MultipartFile.fromBytes(
          'file[]',
          file.bytes,
          filename: file.filename ?? '',
          contentType: file.contentType != null
              ? MediaType.parse(file.contentType!)
              : null,
        ),
      );
    }

    final response = await _apiClient.postMultipart(
      '/files',
      files: multipartFiles,
      fields: fields,
      headers: _session.authenticationHeaders,
      responseDeserializer: UploadFilesResponse.fromJson,
      onUploadProgress: onUploadProgress,
    );

    return response.processedFiles;
  }

  /// Downloads the file with the specified identifier.
  @override
  Future<http.Response> downloadFile(String fileId) async {
    return _apiClient.get<http.Response>(
      '/files/$fileId',
      headers: _session.authenticationHeaders,
    );
  }

  @override
  Future<PresignedUrl> getPresignedUrl(
    String fileId, {
    ImageTransformBase? transform,
  }) async {
    return await _apiClient.get(
      '/files/$fileId/presignedurl',
      query: {
        ...?transform?.toQueryArguments(),
      },
      headers: _session.authenticationHeaders,
      responseDeserializer: PresignedUrl.fromJson,
    );
  }

  /// Deletes a file on the backend.
  ///
  /// Throws an [ApiException] if the deletion fails.
  @override
  Future<void> delete(String fileId) async {
    await _apiClient.delete(
      '/files/$fileId',
      headers: _session.authenticationHeaders,
    );
  }

  /// Downloads the image with the specified identifier, optionally applying
  /// a visual transformation.
  @override
  Future<http.Response> downloadImage(
    String fileId, {
    ImageTransformBase? transform,
  }) async {
    return _apiClient.get<http.Response>(
      '/files/$fileId',
      query: {
        ...?transform?.toQueryArguments(),
      },
      headers: _session.authenticationHeaders,
    );
  }
}
