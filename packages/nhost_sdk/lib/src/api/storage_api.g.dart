// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileMetadata _$FileMetadataFromJson(Map<String, dynamic> json) {
  return FileMetadata(
    key: json['Key'] as String,
    acceptRanges: json['AcceptRanges'] as String,
    lastModified: json['LastModified'] == null
        ? null
        : DateTime.parse(json['LastModified'] as String),
    contentLength: json['ContentLength'] as int,
    eTag: json['ETag'] as String,
    contentType: contentTypeFromString(json['ContentType'] as String),
    nhostMetadata: json['Metadata'] == null
        ? null
        : FileNhostMetadata.fromJson(json['Metadata'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$FileMetadataToJson(FileMetadata instance) =>
    <String, dynamic>{
      'Key': instance.key,
      'AcceptRanges': instance.acceptRanges,
      'LastModified': instance.lastModified?.toIso8601String(),
      'ContentLength': instance.contentLength,
      'ETag': instance.eTag,
      'ContentType': contentTypeToString(instance.contentType),
      'Metadata': instance.nhostMetadata?.toJson(),
    };

FileNhostMetadata _$FileNhostMetadataFromJson(Map<String, dynamic> json) {
  return FileNhostMetadata(
    token: json['token'] as String,
  );
}

Map<String, dynamic> _$FileNhostMetadataToJson(FileNhostMetadata instance) =>
    <String, dynamic>{
      'token': instance.token,
    };
