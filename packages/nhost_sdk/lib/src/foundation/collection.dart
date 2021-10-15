import 'dart:math' show min;

/// Processes int lists moving through the stream, emitting them as sublists
/// of length [chunkLength].
Stream<List<int>> chunkStream(
  Stream<List<int>> stream, {
  required int chunkLength,
}) async* {
  await for (final data in stream) {
    if (data.length < chunkLength) {
      yield data;
    } else {
      for (final chunk in chunkList(data, chunkLength)) {
        yield chunk;
      }
    }
  }
}

/// Chunks [elements] into sublists of size [chunkSize].
Iterable<List<T>> chunkList<T>(List<T> elements, int chunkSize) sync* {
  for (int i = 0; i < elements.length; i += chunkSize) {
    yield elements.sublist(
        i,
        min(
          i + chunkSize,
          elements.length,
        ));
  }
}
