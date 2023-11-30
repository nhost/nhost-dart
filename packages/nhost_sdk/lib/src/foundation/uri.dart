import 'package:path/path.dart';

final _urlPathContext = Context(style: Style.url);

/// Joins together path fragments so that [basePath] and [subPath] are both
/// represented in the resulting string, even if [subPath] starts with a `/`.
String joinSubpath(String basePath, String subPath) {
  final suffix = subPath.endsWith('/') ? '/' : '';
  final path = _urlPathContext.normalize(_urlPathContext.join(
    basePath,
    subPath.startsWith('/') ? '.$subPath' : subPath,
  ));
  return '$path$suffix';
}

/// Generate Endpoint for each service and based on the subdomain
String createNhostServiceEndpoint({
  required String subdomain,
  required String region,
  required String service,
  String apiVersion = 'v1',
  String protocol = 'https',
}) {
  if (region.isEmpty && subdomain == 'local') {
    return '$protocol://$subdomain.$service.nhost.run/$apiVersion';
  }

  // production app, new subdomain approach
  return '$protocol://$subdomain.$service.$region.nhost.run/$apiVersion';
}

extension UriExt on Uri {
  /// Extends a base Uri to include a [subPath], and optionally a new set of
  /// [queryParameters].
  Uri extend(
    String subPath, {
    Map<String, String?>? queryParameters,
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
