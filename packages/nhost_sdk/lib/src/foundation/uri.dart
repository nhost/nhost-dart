import 'package:path/path.dart';

/// Joins together path fragments
final _joinPath = Context(style: Style.url).join;

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
      path: _joinPath(path, subPath.startsWith('/') ? '.$subPath' : subPath),
      queryParameters: query.isNotEmpty ? query : null,
    );
  }
}
