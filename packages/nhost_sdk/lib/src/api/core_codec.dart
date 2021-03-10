/// Serialization for core dart types
library foundation;

import 'dart:io';

/// Deserializes a [ContentType] from its [String] representation.
ContentType contentTypeFromString(String contentTypeString) =>
    contentTypeString == null ? null : ContentType.parse(contentTypeString);

/// Serializes a [ContentType] into its [String] representation.
String contentTypeToString(ContentType contentType) => contentType?.toString();

/// Deserializes a millisecond integer into a [Duration].
Duration durationFromMs(int milliseconds) =>
    milliseconds == null ? null : Duration(milliseconds: milliseconds);

/// Serializes a [Duration] into a milliseconds [int].
int durationToMs(Duration duration) => duration?.inMilliseconds;

/// Deserializes a [UriData] from its [String] representation.
UriData uriDataFromString(String uriDataString) =>
    uriDataString == null ? null : UriData.parse(uriDataString);

/// Serializes a [UriData] into its [String] representation.
String uriDataToString(UriData uriData) => uriData?.toString();
