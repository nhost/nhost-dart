/// Requires when constructing SDK for self-host projects
///
/// https://docs.nhost.io
class ServiceUrls {
  /// {@macro nhost.api.NhostClient.serviceUrls}
  ServiceUrls({
    this.authUrl,
    this.graphqlUrl,
    this.storageUrl,
    this.functionsUrl,
  });

  /// Check out self-hosted nhost dashboard and get your `authUrl`
  final String? authUrl;

  /// Check out self-hosted nhost dashboard and get your `graphqlUrl`
  final String? graphqlUrl;

  /// Check out self-hosted nhost dashboard and get your `storageUrl`
  final String? storageUrl;

  /// Check out self-hosted nhost dashboard and get your `functionsUrl`
  final String? functionsUrl;
}
