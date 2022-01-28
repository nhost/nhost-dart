import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:nhost_sdk/src/http.dart';

import 'api/auth_api_types.dart';

const _hasuraClaimsNamespace = 'https://hasura.io/jwt/claims';

/// Shares authentication information between service classes.
class UserSession {
  UserSession();

  Session? _session;
  Map<String, dynamic>? _hasuraClaims;

  String? get jwt => session?.accessToken;

  String? getClaim(String claim) =>
      _hasuraClaims != null ? _hasuraClaims![claim] : null;

  Map<String, String> get authenticationHeaders {
    return {
      if (jwt != null) authorizationHeader: 'Bearer $jwt',
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
