import 'package:path/path.dart';

/// Joins together path fragments
final _joinPath = Context(style: Style.url).join;

/// Joins together path fragments so that [basePath] and [subPath] are both
/// represented in the resulting string, even if [subPath] starts with a `/`.
String joinSubpath(String basePath, String subPath) =>
    _joinPath(basePath, subPath.startsWith('/') ? '.$subPath' : subPath);

extension UriExt on Uri {
  /// Extends a base Uri to include a [subPath], and optionally a new set of
  /// [queryParameters].
  Uri extend(
    String subPath, {
    Map<String, String> queryParameters,
  }) {
    final query = {
      if (queryParameters != null && queryParameters.isNotEmpty)
        ...queryParameters,
      if (this.queryParameters.isNotEmpty) ...this.queryParameters
    };

    return replace(
      path: joinSubpath(path, subPath),
      queryParameters: query.isNotEmpty ? query : null,
    );
  }
}
