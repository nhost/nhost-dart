import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:nhost_sdk/src/http.dart';

import 'api/auth_api_types.dart';

const _hasuraClaimsNamespace = 'https://hasura.io/jwt/claims';

/// Shares authentication information between service classes.
class UserSession {
  Session? _session;
  Map<String, dynamic>? _hasuraClaims;

  String? get accessToken => session?.accessToken;

  String? getClaim(String claim) =>
      _hasuraClaims != null ? _hasuraClaims![claim] : null;

  /// The set of HTTP headers sent along with Nhost API calls.
  Map<String, String> get authenticationHeaders {
    return {
      if (accessToken != null) authorizationHeader: 'Bearer $accessToken',
    };
  }

  void clear() {
    _session = null;
    _hasuraClaims = null;
  }

  Session? get session => _session;
  set session(Session? session) {
    if (session != null && session.accessToken != null) {
      _session = session;

      final decodedToken = JwtDecoder.decode(session.accessToken!);
      _hasuraClaims =
          decodedToken[_hasuraClaimsNamespace] as Map<String, dynamic>?;
    } else {
      clear();
    }
  }
}
