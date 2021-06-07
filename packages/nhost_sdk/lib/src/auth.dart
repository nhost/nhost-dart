import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'api/api_client.dart';
import 'api/auth_api_types.dart';
import 'auth_store.dart';
import 'debug.dart';
import 'foundation/duration.dart';
import 'http.dart';
import 'session.dart';

/// Signature for callbacks that respond to token changes.
///
/// Registered via [Auth.addTokenChangedCallback].
typedef TokenChangedCallback = void Function();

/// Signature for callbacks that respond to authentication changes.
///
/// Registered via [Auth.addTokenChangedCallback].
typedef AuthStateChangedCallback = void Function({required bool authenticated});

/// Signature for functions that remove their associated callback when called.
typedef UnsubscribeDelegate = void Function();

/// Identifies the refresh token in the [Auth]'s [AuthStore] instance.
const refreshTokenClientStorageKey = 'nhostRefreshToken';

/// The query parameter name for the refresh token provided during OAuth
/// provider-based logins.
const refreshTokenQueryParamName = 'refresh_token';

/// The Nhost Auth service.
///
/// Supports user authentication, MFA, OTP, and various user management
/// functions.
///
/// See https://docs.nhost.io/auth/api-reference for more info.
class Auth {
  /// {@macro nhost.api.NhostClient.baseUrl}
  ///
  /// {@macro nhost.api.NhostClient.authStore}
  ///
  /// {@macro nhost.api.NhostClient.refreshToken}
  ///
  /// {@macro nhost.api.NhostClient.autoLogin}
  ///
  /// {@macro nhost.api.NhostClient.tokenRefreshInterval}
  ///
  /// {@macro nhost.api.NhostClient.httpClientOverride}
  Auth({
    required String baseUrl,
    required UserSession session,
    required AuthStore authStore,
    String? refreshToken,
    bool? autoLogin = true,
    Duration? refreshInterval,
    required http.Client httpClient,
  })  : _apiClient = ApiClient(Uri.parse(baseUrl), httpClient: httpClient),
        _session = session,
        _authStore = authStore,
        _tokenRefreshInterval = refreshInterval,
        _refreshTokenLock = false,
        _loading = true,
        _autoLogin = autoLogin ?? true {
    if (_autoLogin) {
      _refreshToken(refreshToken);
    } else if (refreshToken != null) {
      _authStore.setString(refreshTokenClientStorageKey, refreshToken);
    } else {
      _loading = false;
    }
  }

  final ApiClient _apiClient;
  final AuthStore _authStore;
  final UserSession /*?*/ _session;
  final bool _autoLogin;

  final List<TokenChangedCallback> _tokenChangedFunctions = [];
  final List<AuthStateChangedCallback> _authChangedFunctions = [];

  Timer? _tokenRefreshTimer;
  final Duration? _tokenRefreshInterval;
  bool _refreshTokenLock;

  /// `true` if the service is currently loading.
  ///
  /// While loading, the authentication state is indeterminate.
  bool _loading;

  /// Currently logged-in user, or `null` if unauthenticated.
  User? get currentUser => _currentUser;
  User? _currentUser;

  /// Whether a user is logged in, not logged in, or if a login is in process.
  AuthenticationState get authenticationState {
    if (_loading) return AuthenticationState.inProgress;
    return _session.session != null
        ? AuthenticationState.loggedIn
        : AuthenticationState.loggedOut;
  }

  /// The currently logged-in user's Json Web Token, or `null` if
  /// unauthenticated.
  String? get jwt => _session.jwt;

  String? getClaim(String jwtClaim) => _session.getClaim(jwtClaim);

  /// Releases the service's resources.
  ///
  /// The service's methods cannot be called past this point.
  void close() {
    _apiClient.close();
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

  void _onAuthStateChanged({required bool authenticated}) {
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
    required String email,
    required String password,
    Map<String, String>? userData,
    String? defaultRole,
    List<String>? allowedRoles,
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

    Session? sessionRes;
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

    if (sessionRes!.jwtToken != null) {
      await setSession(sessionRes);
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
    required String email,
    required String password,
  }) async {
    AuthResponse? loginRes;
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

    if (loginRes!.mfa != null) {
      return loginRes;
    }

    await setSession(loginRes.session!);
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
        await _authStore.getString(refreshTokenClientStorageKey);
    try {
      await _apiClient.post(
        '/logout',
        query: {
          'refresh_token': refreshToken,
        },
        data: {
          'all': all,
        },
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
  /// NOTE: This function requires that your project is configured with "NEW
  /// EMAIL VERIFICATION" turned OFF.
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
      headers: _session.authenticationHeaders,
    );
  }

  /// Requests an email change for the logging in user.
  ///
  /// The backend will send an email to the new email address with an activation
  /// link.
  ///
  /// NOTE: This function requires that your project is configured with "NEW
  /// EMAIL VERIFICATION" turned ON.
  ///
  /// Throws an [ApiException] if requesting the email change fails.
  ///
  /// TODO(shyndman): Link to API docs (currently missing)
  Future<void> requestEmailChange({required String newEmail}) async {
    await _apiClient.post(
      '/change-email/request',
      data: {
        'new_email': newEmail,
      },
      headers: _session.authenticationHeaders,
    );
  }

  /// Confirms an email change.
  ///
  /// [ticket] is the server-generated value that was sent to the user's
  /// old email address via [requestEmailChange].
  ///
  /// Throws an [ApiException] if confirming the email change fails.
  ///
  /// NOTE: This function requires that your project is configured with "NEW
  /// EMAIL VERIFICATION" turned ON.
  ///
  /// TODO(shyndman): Link to API docs (currently missing)
  Future<void> confirmEmailChange({required String ticket}) async {
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
    required String oldPassword,
    required String newPassword,
  }) async {
    await _apiClient.post(
      '/change-password',
      data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
      headers: _session.authenticationHeaders,
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
  Future<void> requestPasswordChange({required String email}) async {
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
    required String newPassword,
    required String? ticket,
  }) async {
    await _apiClient.post('/change-password/change', data: {
      'new_password': newPassword,
      'ticket': ticket,
    });
  }

  //#endregion

  //#region Multi-factor authentication

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
      headers: _session.authenticationHeaders,
      // This empty map is required by the server, otherwise it fails
      data: {},
      responseDeserializer: MultiFactorAuthResponse.fromJson,
    );
  }

  /// Enable MFA (Multi-Factor Authentication).
  ///
  /// [totp] is the one-time password generated from an OTP secret, which is
  /// created via the [generateMfa] call.
  ///
  /// Throws an [ApiException] if enabling MFA fails.
  ///
  /// https://docs.nhost.io/auth/api-reference#enable-mfa
  Future<void> enableMfa(String totp) async {
    await _apiClient.post(
      '/mfa/enable',
      headers: _session.authenticationHeaders,
      data: {
        'code': totp,
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
      headers: _session.authenticationHeaders,
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
    required String code,
    required String ticket,
  }) async {
    final res = await _apiClient.post<Session>(
      '/mfa/totp',
      data: {
        'code': code,
        'ticket': ticket,
      },
      responseDeserializer: Session.fromJson,
    );

    await setSession(res);
    return AuthResponse(session: res, user: res.user);
  }

  //#endregion

  //#region OAuth providers

  /// Completes an OAuth provider login, given the Nhost OAuth provider's
  /// [redirectUrl].
  ///
  /// For more information on redirect URLs, see
  /// https://docs.nhost.io/auth/oauth-providers.
  ///
  /// For an example of this in practice, see the `nhost_flutter_auth` package's
  /// OAuthProvider example.
  Future<void> completeOAuthProviderLogin(Uri redirectUrl) async {
    final queryArgs = redirectUrl.queryParameters;
    if (!queryArgs.containsKey(refreshTokenQueryParamName)) {
      return;
    }

    await _refreshToken(queryArgs[refreshTokenQueryParamName]);
  }

  //#endregion

  //#region Token and session Handling

  Future<void> refreshSession() async {
    return _refreshToken();
  }

  Future<void> _refreshToken([String? initRefreshToken]) async {
    final refreshToken = initRefreshToken ??
        await _authStore.getString(refreshTokenClientStorageKey);

    // If there's no refresh token, we're all done.
    if (refreshToken == null) {
      _loading = false;
      return;
    }

    // Set lock to avoid two refresh token request being sent at the same time
    // with the same token. If so, the last request will fail because the
    // first request used the refresh token
    if (_refreshTokenLock) {
      debugPrint('Refresh token already in transit. Halting this request.');
      return;
    }

    Session? res;
    try {
      _refreshTokenLock = true;

      // Make refresh token request
      res = await _apiClient.get(
        '/token/refresh',
        query: {
          'refresh_token': refreshToken,
        },
        responseDeserializer: Session.fromJson,
      );
    } on ApiException catch (e, st) {
      debugPrint('API exception during token refresh');
      debugPrint(e);
      debugPrint(st);

      if (e.statusCode == unauthorizedStatus) {
        await logout();
        return;
      } else {
        return; // Silent fail
      }
    } catch (e, st) {
      debugPrint('Exception during token refresh');
      debugPrint(e);
      debugPrint(st);

      return;
    } finally {
      // Release lock
      _refreshTokenLock = false;
    }

    await setSession(res!);
  }

  /// Updates the [Auth] to begin identifying as the user described by
  /// [session].
  ///
  /// It is CRITICAL that this function be awaited before returning to the user.
  /// Failure to do so will result in very difficult to track down race
  /// conditions.
  @visibleForTesting
  Future<void> setSession(Session session) async {
    final previouslyAuthenticated = authenticationState;
    _session.session = session;
    _currentUser = session.user;

    if (session.refreshToken != null) {
      await _authStore.setString(
          refreshTokenClientStorageKey, session.refreshToken!);
    }

    final jwtExpiresIn = session.jwtExpiresIn;
    final refreshTimerDuration = _tokenRefreshInterval ??
        (jwtExpiresIn != null
            ? max(
                Duration(seconds: 30),
                jwtExpiresIn - Duration(seconds: 45),
              )
            : Duration(seconds: 30)); // 45 sec before expiry

    // Ensure that the previous timer is cancelled.
    _tokenRefreshTimer?.cancel();

    // Start refresh token interval after logging in.
    _tokenRefreshTimer = Timer.periodic(refreshTimerDuration, (_) {
      _refreshToken();
    });

    // We're ready!
    _loading = false;

    _onTokenChanged();
    if (previouslyAuthenticated != AuthenticationState.loggedIn) {
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
      _tokenRefreshTimer!.cancel();
      _tokenRefreshTimer = null;
    }

    // Early exit
    if (authenticationState != AuthenticationState.loggedIn) {
      return;
    }

    _session.clear();
    await _authStore.removeItem(refreshTokenClientStorageKey);

    _loading = false;
    _onTokenChanged();
    _onAuthStateChanged(authenticated: false);
  }

  //#endregion
}

enum AuthenticationState {
  inProgress,
  loggedIn,
  loggedOut,
}
