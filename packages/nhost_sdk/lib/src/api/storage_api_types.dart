/// Describes a file stored by Nhost.
///
/// The fields of this class can be used to fetch the file's contents ([key]),
/// as well as populate the headers of an HttpResponse if you were to serve
/// this file to a client.
class FileMetadata {
  FileMetadata({
    this.key,
    this.acceptRanges,
    this.lastModified,
    this.contentLength,
    this.eTag,
    this.contentType,
    this.nhostMetadata,
  });

  /// Path to file
  final String key;

  /// accept-ranges value for HTTP response header
  final String acceptRanges;

  /// last-modified  value for HTTP response header
  final DateTime lastModified;

  /// content-length value for HTTP response header
  final int contentLength;

  /// etag value for HTTP response header
  final String eTag;

  /// content-type value for HTTP response header
  final String contentType;

  /// Additional Nhost-specific metadata associated with this file
  final FileNhostMetadata nhostMetadata;

  static FileMetadata fromJson(dynamic json) {
    return FileMetadata(
      // TODO(https://github.com/nhost/hasura-backend-plus/issues/436): In
      // order to work around inconsistencies in the backend's naming of this
      // field, we duplicate.
      key: (json['Key'] ?? json['key']) as String,
      acceptRanges: json['AcceptRanges'] as String,
      lastModified: json['LastModified'] == null
          ? null
          : DateTime.parse(json['LastModified'] as String),
      contentLength: json['ContentLength'] as int,
      eTag: json['ETag'] as String,
      contentType: json['ContentType'] as String,
      nhostMetadata: json['Metadata'] == null
          ? null
          : FileNhostMetadata.fromJson(
              json['Metadata'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Key': key,
      'AcceptRanges': acceptRanges,
      'LastModified': lastModified?.toIso8601String(),
      'ContentLength': contentLength,
      'ETag': eTag,
      'ContentType': contentType,
      'Metadata': nhostMetadata?.toJson(),
    };
  }
}

/// Additional Nhost-specific metadata associated with a [FileMetadata]
/// instance.
class FileNhostMetadata {
  FileNhostMetadata({this.token});

  /// TODO(shyndman): What is this?
  final String token;

  static FileNhostMetadata fromJson(dynamic json) {
    return FileNhostMetadata(
      token: json['token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'token': token,
    };
  }
}

/// Instructs the backend on how to transform a stored image.
class ImageTransformConfig {
  ImageTransformConfig({
    this.width,
    this.height,
    this.quality,
  });

  final int width;
  final int height;
  final int quality;

  Map<String, String> toQueryArguments() {
    return {
      if (width != null) 'w': '$width',
      if (height != null) 'h': '$height',
      if (quality != null) 'q': '$quality',
    };
  }
}
