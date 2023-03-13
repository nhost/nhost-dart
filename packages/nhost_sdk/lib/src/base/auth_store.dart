import 'dart:async';

/// Interface implemented by objects responsible for persisting authentication
/// information between restarts of an app.
abstract class AuthStore {
  FutureOr<String?> getString(String key);
  FutureOr<void> setString(String key, String value);
  FutureOr<void> removeItem(String key);
}
