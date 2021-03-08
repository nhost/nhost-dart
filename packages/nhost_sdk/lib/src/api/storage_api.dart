import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

import 'core_codec.dart';

part 'storage_api.g.dart';

@JsonSerializable(fieldRename: FieldRename.pascal)
class File {
  String key;
  String acceptRanges;
  DateTime lastModified;
  int contentLength;
  String eTag;
  @JsonKey(fromJson: contentTypeFromString, toJson: contentTypeToString)
  ContentType contentType;

  static File fromJson(Map<String, dynamic> json) => _$FileFromJson(json);
  Map<String, dynamic> toJson() => _$FileToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class FileMetadata {
  FileMetadata({this.token});
  final String token;

  static FileMetadata fromJson(Map<String, dynamic> json) =>
      _$FileMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$FileMetadataToJson(this);
}
