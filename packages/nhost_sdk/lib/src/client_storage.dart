abstract class ClientStorage {
  Future<String> getString(String key);
  Future<void> setString(String key, String value);
  Future<void> removeItem(String key);
}

/// Implements the [ClientStorage] interface using an internal [Map].
class InMemoryClientStorage implements ClientStorage {
  final Map<String, String> _map = {};

  @override
  Future<String> getString(String key) async => _map[key];

  @override
  Future<void> removeItem(String key) async => _map.remove(key);

  @override
  Future<void> setString(String key, String value) async => _map[key] = value;
}
