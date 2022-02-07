import '../storage_client.dart';

/// Describes a file stored by Nhost.
///
/// The fields of this class can be used to fetch the file's contents ([id]),
/// as well as populate the headers of an HttpResponse if you were to serve
/// this file to a client.
class FileMetadata {
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
  final String id;

  /// Path to file
  final String name;

  /// Size of file in bytes
  final int size;

  /// content-type value for HTTP response header
  final String mimeType;

  /// etag value for HTTP response header
  final String etag;

  ///
  final DateTime createdAt;

  ///
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

class PresignedUrl {
  PresignedUrl({required this.url, required this.expiration});

  final String url;
  final DateTime expiration;

  static PresignedUrl fromJson(dynamic json) {
    return PresignedUrl(
      url: json['url'] as String,
      expiration: DateTime.parse(json['expiration']),
    );
  }
}

/// Instructs the backend on how to transform a stored image.
class ImageTransform {
  ImageTransform({
    this.width,
    this.height,
    this.quality,
    this.blur,
    this.cornerRadius,
  }) : assert(quality == null || (1 <= quality && quality <= 100));

  /// The width of the resulting image.
  final int? width;

  /// The height of the resulting image.
  final int? height;

  /// The quality of the resulting image. Value between 1 and 100 (inclusive).
  final int? quality;

  /// The amount of blur to apply, in pixels.
  final double? blur;

  /// The corner radius to apply to the resulting image.
  final ImageCornerRadius? cornerRadius;

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
class ImageCornerRadius {
  /// Applies the maximum amount of corner radius possible, based on the size
  /// of the image being transformed.
  ImageCornerRadius.full()
      : isFull = true,
        inPixels = null;

  /// Applies a corner radius of [pixels] pixels.
  ImageCornerRadius.pixels(double pixels)
      : isFull = false,
        inPixels = pixels;

  final bool isFull;
  final double? inPixels;

  String toQueryValue() => isFull ? 'full' : inPixels!.toStringAsFixed(1);
}
