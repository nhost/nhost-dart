import 'package:path/path.dart';

final _urlPathContext = Context(style: Style.url);

/// Joins together path fragments
final _joinPath = _urlPathContext.join;

/// Joins together path fragments so that [basePath] and [subPath] are both
/// represented in the resulting string, even if [subPath] starts with a `/`.
String joinSubpath(String basePath, String subPath) {
  final suffix = subPath.endsWith('/') ? '/' : '';
  final path = _urlPathContext.normalize(_joinPath(
    basePath,
    subPath.startsWith('/') ? '.$subPath' : subPath,
  ));
  return '$path$suffix';
}

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
