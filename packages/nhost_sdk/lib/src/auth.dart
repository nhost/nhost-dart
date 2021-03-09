import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';

import 'api/api_client.dart';
import 'api/auth_api.dart';
import 'client_storage.dart';
import 'debug.dart';
import 'foundation/duration.dart';
import 'foundation/string.dart';
import 'session.dart';

typedef TokenChangedCallback = void Function();
typedef AuthChangedCallback = void Function({bool authenticated});
typedef UnsubscribeDelegate = void Function();

const refreshTokenClientStorageKey = 'nhostRefreshToken';

class Auth {
  Auth({
    String baseUrl,
    Duration refreshInterval,
    UserSession session,
    ClientStorage clientStorage,
    bool autoLogin,
  })  : _clientStorage = clientStorage,
        _tokenRefreshInterval = refreshInterval,
        _apiClient = ApiClient(Uri.parse(baseUrl)) {
    _refreshIntervalSleepCheckLastSample = DateTime.now();
    _sampleRate = Duration(milliseconds: 2000); // check every 2 seconds

    _refreshTokenLock = false;
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

  final ApiClient _apiClient;

  final List<TokenChangedCallback> _tokenChangedFunctions = [];
  final List<AuthChangedCallback> _authChangedFunctions = [];

  Timer _tokenRefreshTimer;
  final Duration _tokenRefreshInterval;
  bool _refreshTokenLock;

  Timer _refreshSleepCheckTimer;
  DateTime _refreshIntervalSleepCheckLastSample;
  Duration _sampleRate;

  bool _loading;
  User get currentUser => _currentUser;
  User _currentUser;
  final ClientStorage _clientStorage;

  UserSession _currentSession;

  bool get isAuthenticated {
    if (_loading) return null;
    return _currentSession.session != null;
  }

  String get jwtToken => _currentSession.session?.jwtToken;

  String getClaim(String claim) {
    return _currentSession.getClaim(claim);
  }

  //#region Events

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

  //#endregion

  Future<AuthResponse> register({
    String email,
    String password,
    Map<String, String> userData,
    String defaultRole,
    List<String> allowedRoles,
  }) async {
    final includeRoleOptions = defaultRole != null ||
        (allowedRoles != null && allowedRoles.isNotEmpty);
    final registerOptions = includeRoleOptions
        ? {
            'default_role': defaultRole,
            'allowed_roles': allowedRoles,
          }
        : null;

    Session sessionRes;
    try {
      sessionRes = await _apiClient.post(
        '/register',
        data: {
          'email': email,
          'password': password,
          'user_data': userData,
          if (registerOptions != null) 'register_options': registerOptions,
        },
        responseDeserializer: Session.fromJson,
      );
    } catch (e) {
      rethrow;
    }

    if (sessionRes.jwtToken != null) {
      _setSession(sessionRes);
      return AuthResponse(session: sessionRes, user: sessionRes.user);
    } else {
      // if AUTO_ACTIVATE_NEW_USERS is false
      return AuthResponse(session: null, user: sessionRes.user);
    }
  }

  Future<AuthResponse> login({
    @required String email,
    @required String password,
  }) async {
    AuthResponse loginRes;
    try {
      loginRes = await _apiClient.post(
        '/login',
        data: {
          'email': email,
          'password': password,
          'cookie': false,
        },
        responseDeserializer: AuthResponse.fromJson,
      );
    } catch (e) {
      unawaited(_clearSession());
      rethrow;
    }

    if (loginRes.mfa != null) {
      return loginRes;
    }

    _setSession(loginRes.session);
    return loginRes;
  }

  Future<AuthResponse> logout({
    bool all = false,
  }) async {
    final refreshToken =
        await _clientStorage.getString(refreshTokenClientStorageKey);
    try {
      await _apiClient.post(
        '/logout?refresh_token$refreshToken',
        data: {
          'all': all,
        },
        responseDeserializer: Session.fromJson,
      );
    } catch (e) {
      // noop
      // TODO(shyndman): This probably shouldn't be a noop. If a logout fails,
      // particularly in the ?all=true case, the user should know about it
    }

    unawaited(_clearSession());

    return AuthResponse(session: null, user: null);
  }

  Future<void> activate(String ticket) async {
    await _apiClient.get('/activate?ticket=${ticket}');
  }

  Future<void> changeEmail(String newEmail) async {
    await _apiClient.post('/change-email', data: {
      'new_email': newEmail,
    });
  }

  Future<void> requestEmailChange(String newEmail) async {
    await _apiClient.post('/change-email/request', data: {
      'new_email': newEmail,
    });
  }

  Future<void> confirmEmailChange(String ticket) async {
    await _apiClient.post('/change-email/change', data: {
      'ticket': ticket,
    });
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _apiClient.post('/change-password', data: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  Future<void> requestPasswordChange(String email) async {
    await _apiClient.post('/change-password/request', data: {
      'email': email,
    });
  }

  Future<void> confirmPasswordChange(String newPassword, String ticket) async {
    await _apiClient.post('/change-password/change', data: {
      'new_password': newPassword,
      'ticket': ticket,
    });
  }

  Future<MultiFactorAuthResponse> generateMfa() async {
    return await _apiClient.post(
      '/mfa/generate',
      headers: _generateHeaders(),
      data: {},
      responseDeserializer: MultiFactorAuthResponse.fromJson,
    );
  }

  Future<void> enableMfa(String code) async {
    await _apiClient.post(
      '/mfa/enable',
      headers: _generateHeaders(),
      data: {
        'code': code,
      },
    );
  }

  Future<void> disableMfa({@required String code}) async {
    await _apiClient.post(
      '/mfa/disable',
      data: {
        'code': code,
      },
      headers: _generateHeaders(),
    );
  }

  Future<AuthResponse> mfaTotp({
    @required String code,
    @required String ticket,
  }) async {
    final res = await _apiClient.post<Session>(
      '/mfa/totp',
      data: {
        'code': code,
        'ticket': ticket,
      },
      responseDeserializer: Session.fromJson,
    );

    _setSession(res);
    return AuthResponse(session: res, user: res.user);
  }

  Future<void> refreshSession() async {
    return _refreshToken();
  }

  Map<String, String> _generateHeaders() {
    return {
      HttpHeaders.authorizationHeader:
          'Bearer ${_currentSession.session?.jwtToken}',
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

    Session res;
    try {
      // Set lock to avoid two refresh token request being sent at the same time
      // with the same token. If so, the last request will fail because the
      // first request used the refresh token
      if (_refreshTokenLock) {
        debugPrint('Refresh token already in transit. Halting this request.');
        return;
      }
      _refreshTokenLock = true;

      // Make refresh token request
      res = await _apiClient.get(
        '/token/refresh?refresh_token=$refreshToken',
        responseDeserializer: Session.fromJson,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await logout();
        return;
      } else {
        return; // silent fail
      }
    } catch (e) {
      return;
    } finally {
      // Release lock
      _refreshTokenLock = false;
    }

    _setSession(res);
    _onTokenChanged();
  }

  Future<void> _clearSession() async {
    // early exit
    if (!isAuthenticated) {
      return;
    }

    _tokenRefreshTimer.cancel();
    _tokenRefreshTimer = null;
    _refreshSleepCheckTimer.cancel();
    _refreshSleepCheckTimer = null;

    _currentSession.clear();
    await _clientStorage.removeItem(refreshTokenClientStorageKey);

    _loading = false;
    _onAuthStateChanged(authenticated: false);
  }

  void _setSession(Session session) async {
    final previouslyAuthenticated = isAuthenticated ?? false;
    _currentSession.session = session;
    _currentUser = session.user;

    if (session.refreshToken != null) {
      await _clientStorage.setString(
          refreshTokenClientStorageKey, session.refreshToken);
    }

    final jwtExpiresIn = session.jwtExpiresIn;
    final refreshTimerDuration = _tokenRefreshInterval ??
        max(
          Duration(seconds: 30),
          jwtExpiresIn - Duration(seconds: 45),
        ); // 45 sec before expiry

    // start refresh token interval after logging in
    _tokenRefreshTimer =
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
}
