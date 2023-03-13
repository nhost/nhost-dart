import 'package:nhost_sdk/nhost_sdk.dart';

/// Implements the [AuthStore] interface using an internal [Map].
///
/// As such, all information written to the store is transient, and will not
/// persist between restarts of the app.
///
/// All methods are synchronous.
class InMemoryAuthStore implements AuthStore {
  final Map<String, String> _map = {};

  @override
  String? getString(String key) => _map[key];

  @override
  void removeItem(String key) => _map.remove(key);

  @override
  void setString(String key, String value) => _map[key] = value;
}
