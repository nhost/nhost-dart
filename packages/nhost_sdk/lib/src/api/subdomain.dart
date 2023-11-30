/// Requires when construction SDK for cloud or localhost
///
/// https://docs.nhost.io
class Subdomain {
  /// {@macro nhost.api.NhostClient.subdomain}
  ///
  /// {@macro nhost.api.NhostClient.region}
  Subdomain({
    required this.subdomain,
    required this.region,
  });

  /// Project subdomain (e.g. `ieingiwnginwnfnegqwvdqwdwq`)
  ///
  /// Check out nhost dashboard and get your `subdomain`
  /// for localhost development pass 'local'
  final String subdomain;

  /// Project region (e.g. `eu-central-1`)
  ///
  /// Check out nhost dashboard and get your `region`
  /// Project region is not required during
  /// local development (when `subdomain` is `local`)
  /// in case of local, you pass only empty string ''
  final String region;

  /// When set, the admin secret is sent as a header, `x-hasura-admin-secret`,
  ///
  /// for all requests to GraphQL, Storage, and Functions.
  // final String? adminSecret;
}
