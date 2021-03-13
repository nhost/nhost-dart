import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'api/api_client.dart';
import 'api/auth_api_types.dart';
import 'client_storage.dart';
import 'debug.dart';
import 'foundation/duration.dart';
import 'session.dart';

/// Signature for callbacks that respond to token changes.
///
/// Registered via [Auth.addTokenChangedCallback].
typedef TokenChangedCallback = void Function();

/// Signature for callbacks that respond to authentication changes.
///
/// Registered via [Auth.addTokenChangedCallback].
typedef AuthStateChangedCallback = void Function({bool authenticated});

/// Signature for functions that remove their associated callback when called.
typedef UnsubscribeDelegate = void Function();

/// Identifies the refresh token in the [Auth]'s [ClientStorage] instance.
const refreshTokenClientStorageKey = 'nhostRefreshToken';

/// The Nhost Auth service.
///
/// Supports user authentication, MFA, OTP, and various user management
/// functions.
///
/// See https://docs.nhost.io/auth/api-reference for more info.
class Auth {
  Auth({
    @required String baseUrl,
    Duration refreshInterval,
    UserSession session,
    ClientStorage clientStorage,
    http.Client httpClient,
  })  : _apiClient = ApiClient(Uri.parse(baseUrl), httpClient: httpClient),
        _clientStorage = clientStorage,
        _tokenRefreshInterval = refreshInterval,
        _currentSession = session,
        _refreshTokenLock = false,
        _loading = true;

  final ApiClient _apiClient;
  final ClientStorage _clientStorage;
  final UserSession _currentSession;

  final List<TokenChangedCallback> _tokenChangedFunctions = [];
  final List<AuthStateChangedCallback> _authChangedFunctions = [];

  Timer _tokenRefreshTimer;
  final Duration _tokenRefreshInterval;
  bool _refreshTokenLock;

  /// `true` if the service is currently loading.
  ///
  /// While loading, the authentication state is indeterminate.
  ///
  /// TODO(shyndman): Evaluate whether necessary
  bool _loading;

  /// Currently logged-in user, or `null` if unauthenticated.
  User get currentUser => _currentUser;
  User _currentUser;

  /// The currently logged-in user's Json Web Token, or `null` if
  /// unauthenticated.
  String get jwt => _currentSession.session?.jwtToken;

  /// `true` if the user is authenticated, `false` if they are not, or `null`
  /// if authentication is in process.
  bool get isAuthenticated {
    if (_loading) return null;
    return _currentSession.session != null;
  }

  /// Releases the service's resources.
  ///
  /// The service's methods cannot be called past this point.
  void close() {
    _apiClient?.close();
    _tokenRefreshTimer?.cancel();
  }

  //#region Events

  /// Add a callback that will be invoked when the service's token changes.
  ///
  /// The returned function will remove the callback when called.
  UnsubscribeDelegate addTokenChangedCallback(TokenChangedCallback callback) {
    _tokenChangedFunctions.add(callback);
    return () {
      _tokenChangedFunctions.removeWhere((element) => element == callback);
    };
  }

  /// Add a callback that will be invoked when the service's authentication
  /// state changes.
  ///
  /// The returned function will remove the callback when called.
  UnsubscribeDelegate addAuthStateChangedCallback(
      AuthStateChangedCallback callback) {
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

  /// Creates a user from an [email] and [password].
  ///
  /// If Nhost is configured to not automatically activate new users, the
  /// returned [AuthResponse] will not contain a session. The user must first
  /// activate their account by clicking an activation link sent to their email.
  ///
  /// Throws an [ApiException] if registration fails.
  ///
  /// https://docs.nhost.io/auth/api-reference#register-user
  Future<AuthResponse> register({
    String email,
    String password,
    // TODO(shyndman): This can only be a couple things...why don't we just
    // specify them instead of using a map.
    Map<String, String> userData,
    String defaultRole,
    List<String> allowedRoles,
  }) async {
    userData ??= const {};
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
          'cookie': false,
          if (registerOptions != null) 'register_options': registerOptions,
        },
        responseDeserializer: Session.fromJson,
      );
    } catch (e) {
      rethrow;
    }

    if (sessionRes.jwtToken != null) {
      await _setSession(sessionRes);
      return AuthResponse(session: sessionRes, user: sessionRes.user);
    } else {
      // if AUTO_ACTIVATE_NEW_USERS is false
      return AuthResponse(session: null, user: sessionRes.user);
    }
  }

  /// Authenticates a user using an [email] and [password].
  ///
  /// If the user has multi-factor authentication enabled, the returned
  /// [AuthResponse] will only have its [AuthResponse.mfa] field set, which can
  /// then be used to complete the login via [completeMfaLogin] alongside the user's
  /// one-time-password.
  ///
  /// Throws an [ApiException] if login fails.
  ///
  /// https://docs.nhost.io/auth/api-reference#login-user
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
      await _clearSession();
      rethrow;
    }

    if (loginRes.mfa != null) {
      return loginRes;
    }

    await _setSession(loginRes.session);
    return loginRes;
  }

  /// Logs out the current user.
  ///
  /// If [all] is true, all of the user's devices will be logged out.
  ///
  /// Returns an [AuthResponse] with its fields unset.
  ///
  /// Throws an [ApiException] if logout fails.
  ///
  /// https://docs.nhost.io/auth/api-reference#logout-user
  Future<AuthResponse> logout({
    bool all = false,
  }) async {
    final refreshToken =
        await _clientStorage.getString(refreshTokenClientStorageKey);
    try {
      await _apiClient.post(
        '/logout',
        query: {
          'refresh_token': refreshToken,
        },
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

    await _clearSession();
    return AuthResponse(session: null, user: null);
  }

  /// Activates a user.
  ///
  /// This is only required if Nhost is configured to require manual user
  /// activation.
  ///
  /// Throws an [ApiException] if activation fails.
  ///
  /// https://docs.nhost.io/auth/api-reference#activate-user
  Future<void> activate(String ticket) async {
    await _apiClient.get('/activate', query: {
      'ticket': ticket,
    });
  }

  //#region Email and password changes

  /// Changes the email address of a logged in user.
  ///
  /// Throws an [ApiException] if changing emails fails.
  ///
  /// TODO(shyndman): Link to API docs (currently missing)
  Future<void> changeEmail(String newEmail) async {
    await _apiClient.post(
      '/change-email/',
      data: {
        'new_email': newEmail,
      },
      headers: _generateHeaders(),
    );
  }

  /// Requests an email change for the logging in user.
  ///
  /// The backend will send an email to their current email address with an
  /// activation link.
  ///
  /// Throws an [ApiException] if requesting the email change fails.
  ///
  /// TODO(shyndman): Link to API docs (currently missing)
  Future<void> requestEmailChange({@required String newEmail}) async {
    await _apiClient.post(
      '/change-email/request',
      data: {
        'new_email': newEmail,
      },
      headers: _generateHeaders(),
    );
  }

  /// Confirms an email change.
  ///
  /// [ticket] is the server-generated value that was sent to the user's
  /// old email address via [requestEmailChange].
  ///
  /// Throws an [ApiException] if confirming the email change fails.
  ///
  /// TODO(shyndman): Link to API docs (currently missing)
  Future<void> confirmEmailChange({@required String ticket}) async {
    await _apiClient.post('/change-email/change', data: {
      'ticket': ticket,
    });
  }

  /// Changes the password of a logged in user who knows their current password.
  ///
  /// Throws an [ApiException] if changing passwords fails.
  ///
  /// https://docs.nhost.io/auth/api-reference#change-password
  Future<void> changePassword({
    @required String oldPassword,
    @required String newPassword,
  }) async {
    await _apiClient.post(
      '/change-password',
      data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
      headers: _generateHeaders(),
    );
  }

  /// Requests a password change for a user.
  ///
  /// The backend will send an email to [email] with a ticket that can be used
  /// to confirm the password change, via [confirmPasswordChange].
  ///
  /// Throws an [ApiException] if requesting the password change fails.
  ///
  /// https://docs.nhost.io/auth/api-reference#request-to-change-password
  Future<void> requestPasswordChange(String email) async {
    await _apiClient.post('/change-password/request', data: {
      'email': email,
    });
  }

  /// Confirms an password change.
  ///
  /// [ticket] is the server-generated value that was sent to the user's
  /// email address via [requestPasswordChange].
  ///
  /// Throws an [ApiException] if confirming the password change fails.
  ///
  /// https://docs.nhost.io/auth/api-reference#change-password-with-ticket
  Future<void> confirmPasswordChange({
    @required String newPassword,
    @required String ticket,
  }) async {
    await _apiClient.post('/change-password/change', data: {
      'new_password': newPassword,
      'ticket': ticket,
    });
  }

  //#endregion

  //#region MFA

  /// Generates an MFA (Multi-Factor Authentication) QR-code.
  ///
  /// The user must be logged in to generate this QR-code. The user should scan
  /// the QR-code with their password manager.
  ///
  /// The password manager will return a code (one-time password) that will be
  /// used to [enableMfa] and [disableMfa] for the user and login the user using
  /// TOTP login.
  ///
  /// Throws an [ApiException] if MFA generation fails.
  ///
  /// https://docs.nhost.io/auth/api-reference#generate-mfa-qr-code
  Future<MultiFactorAuthResponse> generateMfa() async {
    return await _apiClient.post(
      '/mfa/generate',
      headers: _generateHeaders(),
      // This empty map is required by the server, otherwise it fails
      data: {},
      responseDeserializer: MultiFactorAuthResponse.fromJson,
    );
  }

  /// Enable MFA (Multi-Factor Authentication).
  ///
  /// [code] is the one-time password generated by the user's password manager.
  ///
  /// To configure the password manager to generate these codes, see
  /// [generateMfa].
  ///
  /// Throws an [ApiException] if enabling MFA fails.
  ///
  /// https://docs.nhost.io/auth/api-reference#enable-mfa
  Future<void> enableMfa(String code) async {
    await _apiClient.post(
      '/mfa/enable',
      headers: _generateHeaders(),
      data: {
        'code': code,
      },
    );
  }

  /// Disable MFA (Multi-Factor Authentication).
  ///
  /// [code] is the one-time password generated by the user's password manager.
  ///
  /// Throws an [ApiException] if disabling MFA fails.
  ///
  /// https://docs.nhost.io/auth/api-reference#disable-mfa
  Future<void> disableMfa(String code) async {
    await _apiClient.post(
      '/mfa/disable',
      data: {
        'code': code,
      },
      headers: _generateHeaders(),
    );
  }

  /// Complete an MFA login using a time-based one-time password.
  ///
  /// This is only necessary if the user has MFA enabled.
  ///
  /// [code] is the OTP generated by the user's password manager, and [ticket]
  /// is the [AuthResponse.mfa.ticket] returned by a preceding call to [login].
  ///
  /// Throws an [ApiException] if logging in via MFA fails.
  ///
  /// https://docs.nhost.io/auth/api-reference#totp-login
  Future<AuthResponse> completeMfaLogin({
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

    await _setSession(res);
    return AuthResponse(session: res, user: res.user);
  }

  //#endregion

  Future<void> refreshSession() async {
    return _refreshToken();
  }

  Map<String, String> _generateHeaders() {
    return {
      if (jwt != null) HttpHeaders.authorizationHeader: 'Bearer $jwt',
    };
  }

  Future<void> _refreshToken([String initRefreshToken]) async {
    final refreshToken = initRefreshToken ??
        await _clientStorage.getString(refreshTokenClientStorageKey);

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
        '/token/refresh',
        query: {
          'refresh_token': refreshToken,
        },
        responseDeserializer: Session.fromJson,
      );
    } on ApiException catch (e) {
      if (e.statusCode == HttpStatus.unauthorized) {
        await logout();
        return;
      } else {
        return; // Silent fail
      }
    } catch (e) {
      return;
    } finally {
      // Release lock
      _refreshTokenLock = false;
    }

    await _setSession(res);
    _onTokenChanged();
  }

  /// Sets the active session to [session], and begins the refresh timer.
  ///
  /// It is CRITICAL that this function be awaited before returning to the user.
  /// Failure to do so will result in very difficult to track down race
  /// conditions.
  Future<void> _setSession(Session session) async {
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

    // Ensure that the previous timer is cancelled.
    _tokenRefreshTimer?.cancel();

    // Start refresh token interval after logging in.
    _tokenRefreshTimer = Timer.periodic(refreshTimerDuration, (_) {
      return _refreshToken();
    });

    // We're ready!
    _loading = false;

    if (!previouslyAuthenticated) {
      _onAuthStateChanged(authenticated: true);
    }
  }

  /// Clears the active session, if any, and removes all derived state.
  ///
  /// It is CRITICAL that this function be awaited before returning to the user.
  /// Failure to do so will result in very difficult to track down race
  /// conditions.
  Future<void> _clearSession() async {
    if (_tokenRefreshTimer != null) {
      _tokenRefreshTimer.cancel();
      _tokenRefreshTimer = null;
    }

    // Early exit
    if (isAuthenticated == false || isAuthenticated == null) {
      return;
    }

    _currentSession.clear();
    await _clientStorage.removeItem(refreshTokenClientStorageKey);

    _loading = false;
    _onAuthStateChanged(authenticated: false);
  }
}
