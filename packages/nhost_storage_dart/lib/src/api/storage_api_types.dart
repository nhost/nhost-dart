import 'dart:typed_data';

import 'package:nhost_sdk/nhost_sdk.dart';

///
/// The fields of this class can be used to fetch the file's contents ([id]),
/// as well as populate the headers of an HttpResponse if you were to serve
/// this file to a client.
class FileMetadata implements FileMetadataBase {
  FileMetadata({
    required this.id,
    required this.name,
    required this.size,
    required this.mimeType,
    required this.etag,
    required this.createdAt,
    required this.bucketId,
  });

  /// UUID identifying the file on the server
  @override
  final String id;

  /// Path to file
  @override
  final String name;

  /// Size of file in bytes
  @override
  final int size;

  /// content-type value for HTTP response header
  @override
  final String mimeType;

  /// etag value for HTTP response header
  @override
  final String etag;

  ///
  @override
  final DateTime createdAt;

  ///
  @override
  final String bucketId;

  @override
  String toString() {
    return 'FileMetadata('
        'id=$id, name=$name, mimeType=$mimeType, size=$size)';
  }

  static FileMetadata fromJson(dynamic json) {
    return FileMetadata(
      id: json['id'],
      name: json['name'] as String,
      size: json['size'] as int,
      mimeType: json['mimeType'] as String,
      etag: json['etag'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      bucketId: json['bucketId'] as String,
    );
  }
}

class PresignedUrl implements PresignedUrlBase {
  PresignedUrl({
    required this.url,
    required this.expiration,
  });

  @override
  final String url;

  @override
  final DateTime expiration;

  static PresignedUrl fromJson(dynamic json) {
    return PresignedUrl(
      url: json['url'] as String,
      expiration: DateTime.now().add(Duration(seconds: json['expiration'])),
    );
  }
}

/// Instructs the backend on how to transform a stored image.
class ImageTransform implements ImageTransformBase {
  ImageTransform({
    this.width,
    this.height,
    this.quality,
    this.blur,
    this.cornerRadius,
  }) : assert(quality == null || (1 <= quality && quality <= 100));

  /// The width of the resulting image.
  @override
  final int? width;

  /// The height of the resulting image.
  @override
  final int? height;

  /// The quality of the resulting image. Value between 1 and 100 (inclusive).
  @override
  final int? quality;

  /// The amount of blur to apply, in pixels.
  @override
  final double? blur;

  /// The corner radius to apply to the resulting image.
  @override
  final ImageCornerRadius? cornerRadius;

  @override
  Map<String, String> toQueryArguments() {
    return {
      if (width != null) 'w': '$width',
      if (height != null) 'h': '$height',
      if (quality != null) 'q': '$quality',
      if (blur != null) 'b': '$blur',
      if (cornerRadius != null) 'r': cornerRadius!.toQueryValue(),
    };
  }
}

/// The corner radius applied to an image.
///
/// Used with [StorageClient.downloadImage].
class ImageCornerRadius implements ImageCornerRadiusBase {
  /// Applies the maximum amount of corner radius possible, based on the size
  /// of the image being transformed.
  ImageCornerRadius.full()
      : isFull = true,
        inPixels = null;

  /// Applies a corner radius of [pixels] pixels.
  ImageCornerRadius.pixels(double pixels)
      : isFull = false,
        inPixels = pixels;

  @override
  final bool isFull;

  @override
  final double? inPixels;

  @override
  String toQueryValue() => isFull ? 'full' : inPixels!.toStringAsFixed(1);
}

/// Generic file representation (like Blob/File in JavaScript).
class FileData {
  FileData(
    this.bytes, {
    this.filename,
    this.contentType,
  });

  /// The file contents as bytes.
  final Uint8List bytes;

  /// Optional filename for the file.
  final String? filename;

  /// Optional MIME type for the file.
  final String? contentType;
}

/// Metadata provided when uploading a new file.
class UploadFileMetadata {
  UploadFileMetadata({
    this.id,
    this.name,
    this.metadata,
  });

  /// Optional custom ID for the file. If not provided, a UUID will be generated.
  final String? id;

  /// Name to assign to the file. If not provided, the original filename will be used.
  final String? name;

  /// Custom metadata to associate with the file.
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// Response containing successfully processed files and error information.
class UploadFilesResponse {
  UploadFilesResponse({
    required this.processedFiles,
  });

  /// List of successfully processed files with their metadata.
  final List<FileMetadata> processedFiles;

  static UploadFilesResponse fromJson(dynamic json) {
    return UploadFilesResponse(
      processedFiles: (json['processedFiles'] as List)
          .map((e) => FileMetadata.fromJson(e))
          .toList(),
    );
  }
}

/// Error response that includes any files that were successfully processed before the error occurred.
class ErrorResponseWithProcessedFiles implements Exception {
  ErrorResponseWithProcessedFiles({
    this.processedFiles = const [],
    required this.message,
    this.data,
  });

  /// List of files that were successfully processed before the error occurred.
  final List<FileMetadata> processedFiles;

  /// Human-readable error message.
  final String message;

  /// Additional data related to the error, if any.
  final Map<String, dynamic>? data;

  @override
  String toString() {
    return 'ErrorResponseWithProcessedFiles(message=$message, processedFiles=${processedFiles.length})';
  }

  static ErrorResponseWithProcessedFiles fromJson(dynamic json) {
    return ErrorResponseWithProcessedFiles(
      processedFiles: json['processedFiles'] != null
          ? (json['processedFiles'] as List)
              .map((e) => FileMetadata.fromJson(e))
              .toList()
          : [],
      message: json['error']['message'] as String,
      data: json['error']['data'] as Map<String, dynamic>?,
    );
  }
}
