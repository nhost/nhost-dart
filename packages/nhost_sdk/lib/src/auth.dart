import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'api/api_client.dart';
import 'api/auth_api_types.dart';
import 'auth_store.dart';
import 'foundation/duration.dart';
import 'http.dart';
import 'logging.dart';
import 'session.dart';

/// Signature for callbacks that respond to token changes.
///
/// Registered via [Auth.addTokenChangedCallback].
typedef TokenChangedCallback = void Function();

/// Signature for callbacks that respond to authentication changes.
///
/// Registered via [Auth.addAuthStateChangedCallback].
typedef AuthStateChangedCallback = void Function(
    AuthenticationState authenticationState);

/// Signature for functions that remove their associated callback when called.
typedef UnsubscribeDelegate = void Function();

/// Identifies the refresh token in the [Auth]'s [AuthStore] instance.
const refreshTokenClientStorageKey = 'nhostRefreshToken';

/// The query parameter name for the refresh token provided during OAuth
/// provider-based logins.
const refreshTokenQueryParamName = 'refresh_token';

/// The Nhost authentication service.
///
/// Supports user authentication, MFA, OTP, and various user management
/// functions.
///
/// See https://docs.nhost.io/reference/sdk/authentication for more info.
class Auth {
  /// {@macro nhost.api.NhostClient.baseUrl}
  ///
  /// {@macro nhost.api.NhostClient.authStore}
  ///
  /// {@macro nhost.api.NhostClient.refreshToken}
  ///
  /// {@macro nhost.api.NhostClient.autoSignIn}
  ///
  /// {@macro nhost.api.NhostClient.tokenRefreshInterval}
  ///
  /// {@macro nhost.api.NhostClient.httpClientOverride}
  Auth({
    required String baseUrl,
    required UserSession session,
    required AuthStore authStore,
    String? refreshToken,
    bool? autoSignIn = true,
    Duration? refreshInterval,
    required http.Client httpClient,
  })  : _apiClient = ApiClient(Uri.parse(baseUrl), httpClient: httpClient),
        _session = session,
        _authStore = authStore,
        _tokenRefreshInterval = refreshInterval,
        _refreshTokenLock = false,
        _loading = true,
        _autoSignIn = autoSignIn ?? true {
    if (_autoSignIn) {
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
  final bool _autoSignIn;

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
        ? AuthenticationState.signedIn
        : AuthenticationState.signedOut;
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
    log.finest('Calling token change callbacks, '
        'jwt.hashCode=${identityHashCode(jwt)}');
    for (final tokenChangedFunction in _tokenChangedFunctions) {
      tokenChangedFunction();
    }
  }

  void _onAuthStateChanged(AuthenticationState authState) {
    log.finest('Calling auth state change callbacks, authState=$authState');
    for (final authChangedFunction in _authChangedFunctions) {
      authChangedFunction(authState);
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
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? locale,
    String? defaultRole,
    List<String>? roles,
    String? displayName,
    String? redirectTo,
  }) async {
    log.finer('Attempting user registration');

    final includeRoleOptions =
        defaultRole != null || (roles != null && roles.isNotEmpty);
    final options = {
      if (locale != null) 'locale': locale,
      if (includeRoleOptions) 'defaultRole': defaultRole,
      if (includeRoleOptions) 'roles': roles,
      if (displayName != null) 'displayName': displayName,
      if (redirectTo != null) 'redirectTo': redirectTo,
    };

    try {
      final res = await _apiClient.post(
        '/signup/email-password',
        jsonBody: {
          'email': email,
          'password': password,
          if (options.isNotEmpty) 'options': options,
        },
        responseDeserializer: AuthResponse.fromJson,
      );
      log.finer('Registration successful');

      if (res.session?.accessToken != null) {
        await setSession(res.session!);
        return res;
      } else {
        // if AUTO_ACTIVATE_NEW_USERS is false
        return AuthResponse(session: null, user: null);
      }
    } catch (e) {
      log.finer('Registration failed');
      rethrow;
    }
  }

  /// Authenticates a user using an [email] and [password].
  ///
  /// If the user has multi-factor authentication enabled, the returned
  /// [AuthResponse] will only have its [AuthResponse.mfa] field set, which can
  /// then be used to complete the login via [completeMfaSignIn] alongside the user's
  /// one-time-password.
  ///
  /// Throws an [ApiException] if login fails.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    log.finer('Attempting login');
    AuthResponse? loginRes;
    try {
      loginRes = await _apiClient.post(
        '/signin/email-password',
        jsonBody: {
          'email': email,
          'password': password,
        },
        responseDeserializer: AuthResponse.fromJson,
      );
    } catch (e, st) {
      log.finer('Sign in failed', e, st);
      await _clearSession();
      rethrow;
    }

    // If multi-factor is enabled, a second step is required before we've fully
    // logged in.
    if (loginRes!.mfa != null) {
      log.finer('Sign in requires MFA');
      return loginRes;
    }

    log.finer('Sign in successful');
    await setSession(loginRes.session!);
    return loginRes;
  }

  /// Logs out the current user.
  ///
  /// If [all] is true, all of the user's devices will be logged out.
  ///
  /// Returns an [AuthResponse] with its fields unset.
  ///
  /// Throws an [ApiException] if sign out fails.
  Future<AuthResponse> signOut({
    bool all = false,
  }) async {
    log.finer('Attempting sign out');
    final refreshToken =
        await _authStore.getString(refreshTokenClientStorageKey);
    try {
      await _apiClient.post(
        '/signout',
        jsonBody: {
          'refreshToken': refreshToken,
          'all': all,
        },
      );
      log.finer('Sign out successful');
    } catch (e, st) {
      log.finer('Sign out failed', e, st);

      // noop
      // TODO(shyndman): This probably shouldn't be a noop. If a signout fails,
      // particularly in the ?all=true case, the user should know about it
    }

    await _clearSession();
    return AuthResponse(session: null, user: null);
  }

  //#region Email and password changes

  /// Changes the email address of a logged in user.
  ///
  /// NOTE: This function requires that your project is configured with "NEW
  /// EMAIL VERIFICATION" turned OFF.
  ///
  /// Throws an [ApiException] if changing emails fails.
  Future<void> changeEmail(String newEmail) async {
    await _apiClient.post(
      '/user/email/change',
      jsonBody: {
        'newEmail': newEmail,
      },
      headers: _session.authenticationHeaders,
    );
  }

  /// Changes the password of the logged in user.
  ///
  /// Throws an [ApiException] if changing passwords fails.
  Future<void> changePassword({
    required String newPassword,
  }) async {
    await _apiClient.post(
      '/user/password',
      jsonBody: {
        'newPassword': newPassword,
      },
      headers: _session.authenticationHeaders,
    );
  }

  /// Resets a user's password.
  ///
  /// Throws an [ApiException] if requesting the password change fails.
  Future<void> resetPassword({
    required String email,
    String? redirectTo,
  }) async {
    await _apiClient.post('/user/password/reset', jsonBody: {
      'email': email,
      if (redirectTo != null)
        'options': {
          'redirectTo': redirectTo,
        },
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
  Future<MultiFactorAuthResponse> generateMfa() async {
    return await _apiClient.get(
      '/mfa/totp/generate',
      headers: _session.authenticationHeaders,
      responseDeserializer: MultiFactorAuthResponse.fromJson,
    );
  }

  /// Enable MFA (Multi-Factor Authentication).
  ///
  /// [totp] is the one-time password generated from an OTP secret, which is
  /// created via the [generateMfa] call.
  ///
  /// Throws an [ApiException] if enabling MFA fails.
  Future<void> enableMfa(String totp) async {
    await _apiClient.post(
      '/user/mfa',
      headers: _session.authenticationHeaders,
      jsonBody: {
        'code': totp,
        'activeMfaType': 'totp',
      },
    );
  }

  /// Disable MFA (Multi-Factor Authentication).
  ///
  /// [code] is the one-time password generated by the user's password manager.
  ///
  /// Throws an [ApiException] if disabling MFA fails.
  Future<void> disableMfa(String code) async {
    await _apiClient.post(
      '/user/mfa',
      jsonBody: {
        'code': code,
        'activeMfaType': null,
      },
      headers: _session.authenticationHeaders,
    );
  }

  /// Complete an MFA login using a time-based one-time password.
  ///
  /// This is only necessary if the user has MFA enabled.
  ///
  /// [otp] is the OTP generated by the user's password manager, and [ticket]
  /// is the [AuthResponse.mfa.ticket] returned by a preceding call to [signIn].
  ///
  /// Throws an [ApiException] if logging in via MFA fails.
  Future<AuthResponse> completeMfaSignIn({
    required String otp,
    required String ticket,
  }) async {
    final res = await _apiClient.post<AuthResponse>(
      '/signin/mfa/totp',
      jsonBody: {
        'otp': otp,
        'ticket': ticket,
      },
      responseDeserializer: AuthResponse.fromJson,
    );

    await setSession(res.session!);
    return res;
  }

  //#endregion

  //#region OAuth providers

  /// Completes an OAuth provider login, given the Nhost OAuth provider's
  /// [redirectUrl].
  ///
  /// For more information on redirect URLs, see
  /// https://docs.nhost.io/platform/authentication/social-login.
  ///
  /// For an example of this in practice, see the `nhost_flutter_auth` package's
  /// OAuthProvider example.
  Future<void> completeOAuthProviderSignIn(Uri redirectUrl) async {
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
    log.finest('Session refresh requested');

    final refreshToken = initRefreshToken ??
        await _authStore.getString(refreshTokenClientStorageKey);

    // If there's no refresh token, we're all done.
    if (refreshToken == null) {
      log.finest('No refresh token. Halting request.');
      _loading = false;
      _onAuthStateChanged(authenticationState);
      return;
    }

    // Set lock to avoid two refresh token request being sent at the same time
    // with the same token. If so, the last request will fail because the
    // first request used the refresh token
    if (_refreshTokenLock) {
      log.finest('Session refresh already in progress. Halting this request.');
      return;
    }

    Session? res;
    try {
      _refreshTokenLock = true;

      // Make refresh token request
      log.finest('Making session refresh request');
      res = await _apiClient.post(
        '/token',
        jsonBody: {
          'refreshToken': refreshToken,
        },
        responseDeserializer: Session.fromJson,
      );
    } on ApiException catch (e, st) {
      if (e.statusCode == unauthorizedStatus) {
        log.finest('Unauthorized refresh token. Forcing signout.');
        await signOut();
        return;
      } else {
        log.severe('API exception during token refresh', e, st);
        return;
      }
    } catch (e, st) {
      log.severe('Exception during token refresh', e, st);
      return;
    } finally {
      // Release lock
      _refreshTokenLock = false;
    }

    await setSession(res!);
  }

  /// Updates the [Auth] to begin identifying as the user described by
  /// [session].
  @visibleForTesting
  Future<void> setSession(Session session) async {
    // It is CRITICAL that this function be awaited before returning to the
    // user. Failure to do so will result in very difficult to track down race
    // conditions.

    log.finest(
        'Setting session, jwt.hashCode=${identityHashCode(session.accessToken)}');

    final previouslyAuthenticated = authenticationState;
    _session.session = session;
    _currentUser = session.user;

    if (session.refreshToken != null) {
      await _authStore.setString(
          refreshTokenClientStorageKey, session.refreshToken!);
    }

    final jwtExpiresIn = session.accessTokenExpiresIn;
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
    log.finest('Creating token refresh timer, duration=$refreshTimerDuration');
    _tokenRefreshTimer = Timer(refreshTimerDuration, () {
      log.finest('Refresh timer elapsed');
      _refreshToken();
    });

    // We're ready!
    _loading = false;

    _onTokenChanged();
    if (previouslyAuthenticated != AuthenticationState.signedIn) {
      _onAuthStateChanged(AuthenticationState.signedIn);
    }
  }

  /// Clears the active session, if any, and removes all derived state.
  ///
  /// It is CRITICAL that this function be awaited before returning to the user.
  /// Failure to do so will result in very difficult to track down race
  /// conditions.
  Future<void> _clearSession() async {
    log.finest('Clearing session');

    if (_tokenRefreshTimer != null) {
      _tokenRefreshTimer!.cancel();
      _tokenRefreshTimer = null;
    }

    // Early exit
    //
    // There could be case when the authenticationState is inProgress and signout
    // is called. For example, if the refresh token has expired. In that case it
    // is important to to clear out the session and remove the refresh token
    // from storage.
    if (authenticationState == AuthenticationState.signedOut) {
      return;
    }

    _session.clear();
    await _authStore.removeItem(refreshTokenClientStorageKey);

    _loading = false;
    _onTokenChanged();
    _onAuthStateChanged(AuthenticationState.signedOut);
  }

  //#endregion
}

enum AuthenticationState {
  inProgress,
  signedIn,
  signedOut,
}
