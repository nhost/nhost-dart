import 'package:jwt_decoder/jwt_decoder.dart';

import 'api/auth_api_types.dart';

const _hasuraClaimsNamespace = 'https://hasura.io/jwt/claims';

class UserSession {
  Session _session;
  Map<String, dynamic> _hasuraClaims;

  void clear() {
    _session = null;
    _hasuraClaims = null;
  }

  Session get session => _session;
  set session(Session session) {
    _session = session;

    final decodedToken = JwtDecoder.decode(session.jwtToken);
    _hasuraClaims =
        decodedToken[_hasuraClaimsNamespace] as Map<String, dynamic>;
  }

  String getClaim(String claim) {
    return _hasuraClaims != null ? _hasuraClaims[claim] : null;
  }
}
