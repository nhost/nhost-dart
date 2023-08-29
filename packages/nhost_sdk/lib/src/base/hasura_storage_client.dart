import 'package:http/http.dart' as http;

import '../foundation/types.dart';

abstract class FileMetadataBase {
  FileMetadataBase({
    required this.id,
    required this.name,
    required this.size,
    required this.mimeType,
    required this.etag,
    required this.createdAt,
    required this.bucketId,
  });

  final String id;
  final String name;
  final int size;
  final String mimeType;
  final String etag;
  final DateTime createdAt;
  final String bucketId;
}

abstract class PresignedUrlBase {
  PresignedUrlBase({
    required this.expiration,
    required this.url,
  });

  final String url;
  final DateTime expiration;
}

abstract class ImageTransformBase {
  ImageTransformBase({
    this.width,
    this.height,
    this.quality,
    this.blur,
    this.cornerRadius,
  });

  final int? width;
  final int? height;
  final int? quality;
  final double? blur;
  final ImageCornerRadiusBase? cornerRadius;

  Map<String, String> toQueryArguments();
}

abstract class ImageCornerRadiusBase {
  ImageCornerRadiusBase({
    required this.isFull,
    this.inPixels,
  });

  final bool isFull;
  final double? inPixels;

  String toQueryValue();
}

abstract class HasuraStorageClient {
  void close();

  Future<FileMetadataBase> uploadBytes({
    required String fileName,
    required List<int> fileContents,
    String? fileId,
    String? bucketId,
    String mimeType,
    UploadProgressCallback? onUploadProgress,
  });

  Future<FileMetadataBase> uploadString({
    required String fileName,
    required String fileContents,
    String? fileId,
    String? bucketId,
    String mimeType,
    UploadProgressCallback? onUploadProgress,
  });

  Future<http.Response> downloadFile(String fileId);
  Future<http.Response> downloadImage(
    String fileId, {
    ImageTransformBase? transform,
  });
  Future<PresignedUrlBase> getPresignedUrl(
    String fileId, {
    ImageTransformBase? transform,
  });
  Future<void> delete(String fileId);
}