import 'dart:async';

/// Interface implemented by objects responsible for persisting authentication
/// information between restarts of the process.
abstract class ClientStorage {
  FutureOr<String> getString(String key);
  FutureOr<void> setString(String key, String value);
  FutureOr<void> removeItem(String key);
}

/// Implements the [ClientStorage] interface using an internal [Map].
///
/// All methods are synchronous.
class InMemoryClientStorage implements ClientStorage {
  final Map<String, String> _map = {};

  @override
  String getString(String key) => _map[key];

  @override
  void removeItem(String key) => _map.remove(key);

  @override
  void setString(String key, String value) => _map[key] = value;
}
