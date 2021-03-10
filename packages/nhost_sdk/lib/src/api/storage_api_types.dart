import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

import 'core_codec.dart';

part 'storage_api_types.g.dart';

@JsonSerializable(fieldRename: FieldRename.pascal, explicitToJson: true)
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

  final String key;
  final String acceptRanges;
  final DateTime lastModified;
  final int contentLength;
  final String eTag;
  @JsonKey(fromJson: contentTypeFromString, toJson: contentTypeToString)
  final ContentType contentType;
  @JsonKey(name: 'Metadata')
  final FileNhostMetadata nhostMetadata;

  static FileMetadata fromJson(dynamic json) => _$FileMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$FileMetadataToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class FileNhostMetadata {
  FileNhostMetadata({this.token});
  final String token;

  static FileNhostMetadata fromJson(dynamic json) =>
      _$FileNhostMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$FileNhostMetadataToJson(this);
}
