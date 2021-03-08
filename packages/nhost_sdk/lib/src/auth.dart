import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';

import 'api/auth_api.dart';
import 'client_storage.dart';
import 'debug.dart';
import 'foundation.dart';
import 'session.dart';

typedef TokenChangedCallback = void Function();
typedef AuthChangedCallback = void Function({bool authenticated});
typedef UnsubscribeDelegate = void Function();

const refreshTokenClientStorageKey = 'nhostRefreshToken';

class Auth {
  final _httpClient = HttpClient();

  final List<TokenChangedCallback> _tokenChangedFunctions = [];
  final List<AuthChangedCallback> _authChangedFunctions = [];

  Timer _refreshTimer;
  final Duration _refreshInterval;

  final ClientStorage _clientStorage;

  bool _refreshTokenLock;
  Uri _baseUrl;
  User _currentUser;
  UserSession _currentSession;
  bool _loading;
  Timer _refreshSleepCheckTimer;
  DateTime _refreshIntervalSleepCheckLastSample;
  Duration _sampleRate;

  Auth({
    String baseUrl,
    Duration refreshInterval,
    UserSession session,
    ClientStorage clientStorage,
    bool autoLogin,
  })  : _clientStorage = clientStorage,
        _refreshInterval = refreshInterval {
    _refreshIntervalSleepCheckLastSample = DateTime.now();
    _sampleRate = Duration(milliseconds: 2000); // check every 2 seconds

    _refreshTokenLock = false;
    _baseUrl = Uri.parse(baseUrl);
    _loading = true;

    _currentUser = null;
    _currentSession = session;

    // Get refresh token from query param (from external OAuth provider
    // callback)

    // If empty string, then set it to null
    // NOTE: This was previously populated via the URL. Do we need to allow
    // this to be supplied?
    // refreshToken = refreshToken ? refreshToken : null;

    // if (autoLogin) {
    //   _autoLogin(refreshToken);
    // } else if (refreshToken) {
    //   _setItem('nhostRefreshToken', refreshToken);
    // }
  }

  User get user => _currentUser;

  Future<AuthResponse> register({
    String email,
    String password,
    Map<String, String> userData,
    String defaultRole,
    List<String> allowedRoles,
  }) async {
    final registerOptions =
        defaultRole != null || (allowedRoles != null && allowedRoles.isNotEmpty)
            ? {
                'default_role': defaultRole,
                'allowed_roles': allowedRoles,
              }
            : null;

    AuthResponse res;
    try {
      res = await _post('/register', data: {
        'email': email,
        'password': password,
        'user_data': userData,
        if (registerOptions != null) 'register_options': registerOptions,
      });
    } catch (e) {
      rethrow;
    }

    if (res.session.jwtToken != null) {
      _setSession(res.session);
      return res;
    } else {
      // if AUTO_ACTIVATE_NEW_USERS is false
      return AuthResponse(session: null, user: res.user);
    }
  }

  Future<AuthResponse> login({
    @required String email,
    @required String password,
  }) async {
    AuthResponse res;
    try {
      res = await _post('/login', data: {
        'email': email,
        'password': password,
      });
    } catch (e) {
      unawaited(_clearSession());
      rethrow;
    }

    if (res.mfa != null) {
      return AuthResponse(
        session: null,
        user: null,
        mfa: MultiFactorAuthenticationInfo(
          ticket: res.mfa.ticket,
        ),
      );
    }

    _setSession(res.session);
    return res;
  }

  Future<AuthResponse> logout({
    bool all = false,
  }) async {
    final refreshToken =
        await _clientStorage.getString(refreshTokenClientStorageKey);
    try {
      await _post('/logout?refresh_token$refreshToken', data: {
        'all': all,
      });
    } catch (e) {
      // noop
    }

    unawaited(_clearSession());

    return AuthResponse(session: null, user: null);
  }

  UnsubscribeDelegate addTokenChangedCallback(TokenChangedCallback callback) {
    _tokenChangedFunctions.add(callback);
    return () {
      _tokenChangedFunctions.removeWhere((element) => element == callback);
    };
  }

  UnsubscribeDelegate addAuthStateChangedCallback(
      AuthChangedCallback callback) {
    _authChangedFunctions.add(callback);
    return () {
      _authChangedFunctions.removeWhere((element) => element == callback);
    };
  }

  bool get isAuthenticated {
    if (_loading) return null;
    return _currentSession.session != null;
  }

  String get jwtToken {
    return _currentSession.session?.jwtToken;
  }

  String getClaim(String claim) {
    return _currentSession.getClaim(claim);
  }

  Future<void> refreshSession() async {
    return _refreshToken();
  }

  Future<void> activate(String ticket) async {
    await _get('/activate?ticket=${ticket}');
  }

  Future<void> changeEmail(String newEmail) async {
    await _post('/change-email', data: {
      'new_email': newEmail,
    });
  }

  Future<void> requestEmailChange(String newEmail) async {
    await _post('/change-email/request', data: {
      'new_email': newEmail,
    });
  }

  Future<void> confirmEmailChange(String ticket) async {
    await _post('/change-email/change', data: {
      'ticket': ticket,
    });
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _post('/change-password', data: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  Future<void> requestPasswordChange(String email) async {
    await _post('/change-password/request', data: {
      'email': email,
    });
  }

  Future<void> confirmPasswordChange(String newPassword, String ticket) async {
    await _post('/change-password/change', data: {
      'new_password': newPassword,
      'ticket': ticket,
    });
  }

  Future<void> MFAGenerate() async {
    final res = await _post('/mfa/generate');
    return res.data;
  }

  Future<void> MFAEnable(String code) async {
    await _post('/mfa/enable', data: {
      'code': code,
    });
  }

  Future<void> disableMfa(String code) async {
    await _post('/mfa/disable', data: {
      'code': code,
    });
  }

  Future<AuthResponse> mfaTotp({
    @required String code,
    @required String ticket,
  }) async {
    final res = await _post<AuthResponse>('/mfa/totp', data: {
      'code': code,
      'ticket': ticket,
    });

    _setSession(res.session);
    return res;
  }

  Map<String, String> _generateHeaders() {
    return {
      'Authorization': 'Bearer ${_currentSession.session?.jwtToken}',
    };
  }

  void _autoLogin(String refreshToken) {
    _refreshToken(refreshToken);
  }

  Future<void> _refreshToken([String initRefreshToken]) async {
    final refreshToken = initRefreshToken ??
        await _clientStorage.getString(refreshTokenClientStorageKey);

    if (refreshToken.isNullOrEmpty) {
      // Place at end of call-stack to let frontend get 'null' first (to match
      // SSR)
      // TODO(shyndman): Do we need this?
      unawaited(Future.microtask(_clearSession));
      return;
    }

    var res;
    try {
      // Set lock to avoid two refresh token request being sent at the same time
      // with the same token. If so, the last request will fail because the
      // first request used the refresh token
      if (_refreshTokenLock) {
        return debugPrint(
            'Refresh token already in transit. Halting this request.');
      }
      _refreshTokenLock = true;

      // make refresh token request
      res = await _get('/token/refresh?refresh_token=$refreshToken');
    } catch (e) {
      if (e.response?.status == 401) {
        await logout();
        return;
      } else {
        return; // silent fail
      }
    } finally {
      // Release lock
      _refreshTokenLock = false;
    }

    _setSession(res.data);
    _onTokenChanged();
  }

  void _onTokenChanged() {
    for (final tokenChangedFunction in _tokenChangedFunctions) {
      tokenChangedFunction();
    }
  }

  void _onAuthStateChanged({@required bool authenticated}) {
    for (final authChangedFunction in _authChangedFunctions) {
      authChangedFunction(authenticated: authenticated);
    }
  }

  Future<void> _clearSession() async {
    // early exit
    if (!isAuthenticated) {
      return;
    }

    _refreshTimer.cancel();
    _refreshTimer = null;
    _refreshSleepCheckTimer.cancel();
    _refreshSleepCheckTimer = null;

    _currentSession.clear();
    await _clientStorage.removeItem(refreshTokenClientStorageKey);

    _loading = false;
    _onAuthStateChanged(authenticated: false);
  }

  void _setSession(Session session) async {
    final previouslyAuthenticated = isAuthenticated;
    _currentSession.session = session;
    _currentUser = session.user;

    if (session.refreshToken != null) {
      await _clientStorage.setString(
          refreshTokenClientStorageKey, session.refreshToken);
    }

    final jwtExpiresIn = session.jwtExpiresIn;
    final refreshTimerDuration = _refreshInterval ??
        Duration(
          milliseconds: max(
            30 * 1000,
            jwtExpiresIn.inMilliseconds - 45000,
          ),
        ); // 45 sec before expiry

    // start refresh token interval after logging in
    _refreshTimer =
        Timer.periodic(refreshTimerDuration, (_) => _refreshToken());

    // refresh token after computer has been sleeping
    // https://stackoverflow.com/questions/14112708/start-calling-js-function-when-pc-wakeup-from-sleep-mode
    _refreshIntervalSleepCheckLastSample = DateTime.now();
    _refreshSleepCheckTimer = Timer.periodic(_sampleRate, (_) {
      final elapsed =
          DateTime.now().difference(_refreshIntervalSleepCheckLastSample);
      if (elapsed >= _sampleRate * 2) {
        _refreshToken();
      }
      _refreshIntervalSleepCheckLastSample = DateTime.now();
    });

    _loading = false;

    if (!previouslyAuthenticated) {
      _onAuthStateChanged(authenticated: true);
    }
  }

  Future<ResponseType> _get<ResponseType>(String path) {
    ;
  }

  Future<ResponseType> _post<ResponseType>(
    String path, {
    Map<String, dynamic> data,
    ResponseType Function(Map<String, dynamic>) deserializer,
  }) async {}
}
