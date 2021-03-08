// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

File _$FileFromJson(Map<String, dynamic> json) {
  return File()
    ..key = json['Key'] as String
    ..acceptRanges = json['AcceptRanges'] as String
    ..lastModified = json['LastModified'] == null
        ? null
        : DateTime.parse(json['LastModified'] as String)
    ..contentLength = json['ContentLength'] as int
    ..eTag = json['ETag'] as String
    ..contentType = contentTypeFromString(json['ContentType'] as String);
}

Map<String, dynamic> _$FileToJson(File instance) => <String, dynamic>{
      'Key': instance.key,
      'AcceptRanges': instance.acceptRanges,
      'LastModified': instance.lastModified?.toIso8601String(),
      'ContentLength': instance.contentLength,
      'ETag': instance.eTag,
      'ContentType': contentTypeToString(instance.contentType),
    };

FileMetadata _$FileMetadataFromJson(Map<String, dynamic> json) {
  return FileMetadata(
    token: json['token'] as String,
  );
}

Map<String, dynamic> _$FileMetadataToJson(FileMetadata instance) =>
    <String, dynamic>{
      'token': instance.token,
    };
