/// Base class for exceptions used by the Nhost packages.
class NhostException implements Exception {}

/// Thrown when a request cannot reach the server at all — no TCP connection,
/// DNS failure, timeout before the server responds, etc.
///
/// Distinct from [ApiException], which requires an HTTP response from the
/// server. Use this to show "no internet connection" UI.
///
/// ```dart
/// try {
///   await Nhost.instance.auth.signIn(email: e, password: p);
/// } on NhostNetworkException catch (e) {
///   // device is offline or server is unreachable
/// } on ApiException catch (e) {
///   // server responded with a 4xx/5xx
/// }
/// ```
class NhostNetworkException extends NhostException {
  NhostNetworkException({required this.cause, this.causeStackTrace});

  /// The underlying exception that caused the network failure
  /// (e.g. [SocketException], [TimeoutException]).
  final Object cause;
  final StackTrace? causeStackTrace;

  @override
  String toString() => 'NhostNetworkException: $cause';
}
