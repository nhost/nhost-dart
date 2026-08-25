import 'package:nhost_dart/nhost_dart.dart';
import 'package:nhost_sdk/nhost_sdk.dart';

/// Minimal fake that drives auth state changes without a real server.
class FakeAuthClient implements NhostAuthClient {
  FakeAuthClient(this._state);

  AuthenticationState _state;
  User? _user;
  // Cached UserSession — built once in simulateSignIn to avoid repeated
  // JwtDecoder.decode calls that would fail on every userSession getter access.
  UserSession _cachedSession = UserSession();

  final List<AuthStateChangedCallback> _listeners = [];

  void simulateSignIn(User user, Session session) {
    _user = user;
    _cachedSession = UserSession()..session = session;
    _state = AuthenticationState.signedIn;
    for (final l in List.of(_listeners)) {
      l(AuthenticationState.signedIn);
    }
  }

  void simulateSignOut() {
    _user = null;
    _cachedSession = UserSession();
    _state = AuthenticationState.signedOut;
    for (final l in List.of(_listeners)) {
      l(AuthenticationState.signedOut);
    }
  }

  @override
  AuthenticationState get authenticationState => _state;

  @override
  User? get currentUser => _user;

  @override
  UserSession get userSession => _cachedSession;

  @override
  UnsubscribeDelegate addAuthStateChangedCallback(
      AuthStateChangedCallback callback) {
    _listeners.add(callback);
    return () => _listeners.remove(callback);
  }

  // --- unused stubs ---
  @override
  String? get accessToken => null;
  @override
  String? getClaim(String c) => null;
  @override
  void close() {}
  @override
  UnsubscribeDelegate addTokenChangedCallback(TokenChangedCallback cb) =>
      () {};
  @override
  UnsubscribeDelegate addSessionRefreshFailedCallback(
          SessionRefreshFailedCallback cb) =>
      () {};
  @override
  Future<AuthResponse> signUp(
          {required String email,
          required String password,
          String? locale,
          String? defaultRole,
          Map<String, Object?>? metadata,
          List<String>? roles,
          String? displayName,
          String? redirectTo,
          String? turnstileResponse}) =>
      throw UnimplementedError();
  @override
  Future<AuthResponse> signInEmailPassword(
          {required String email, required String password}) =>
      throw UnimplementedError();
  @override
  Future<AuthResponse> signInIdToken(
          {required String provider,
          required String idToken,
          String? nonce,
          String? locale,
          String? defaultRole,
          Map<String, Object?>? metadata,
          List<String>? roles,
          String? displayName,
          String? redirectTo}) =>
      throw UnimplementedError();
  @override
  Future<void> linkIdToken(
          {required String provider,
          required String idToken,
          String? nonce}) =>
      throw UnimplementedError();
  @override
  Future<void> signInWithEmailPasswordless(
          {required String email,
          String? locale,
          String? defaultRole,
          Map<String, Object?>? metadata,
          List<String>? roles,
          String? displayName,
          String? redirectTo}) =>
      throw UnimplementedError();
  @override
  Future<void> signInAnonymous(String? displayName, String? locale,
          Map<String, dynamic>? metadata) =>
      throw UnimplementedError();
  @override
  Future<void> deanonymizeUser(DeanonymizeOptions options) =>
      throw UnimplementedError();
  @override
  Future<void> signInWithSmsPasswordless(
          {required String phoneNumber,
          String? locale,
          String? defaultRole,
          Map<String, Object?>? metadata,
          List<String>? roles,
          String? displayName,
          String? redirectTo}) =>
      throw UnimplementedError();
  @override
  Future<AuthResponse> completeSmsPasswordlessSignIn(
          String phoneNumber, String otp) =>
      throw UnimplementedError();
  @override
  Future<void> signInEmailOTP(
          {required String email,
          String? locale,
          String? defaultRole,
          Map<String, Object?>? metadata,
          List<String>? roles,
          String? displayName,
          String? redirectTo}) =>
      throw UnimplementedError();
  @override
  Future<AuthResponse> verifyEmailOTP(
          {required String email, required String otp}) =>
      throw UnimplementedError();
  @override
  Future<AuthResponse> signInWithStoredCredentials() =>
      throw UnimplementedError();
  @override
  Future<AuthResponse> signInWithRefreshToken(String refreshToken) =>
      throw UnimplementedError();
  @override
  Future<AuthResponse> signOut({bool all = false}) =>
      throw UnimplementedError();
  @override
  Future<void> sendVerificationEmail(
          {required String email, String? redirectTo}) =>
      throw UnimplementedError();
  @override
  Future<void> changeEmail(String newEmail) => throw UnimplementedError();
  @override
  Future<void> changePassword(
          {required String newPassword, String? ticket}) =>
      throw UnimplementedError();
  @override
  Future<void> resetPassword({required String email, String? redirectTo}) =>
      throw UnimplementedError();
  @override
  Future<MultiFactorAuthResponse> generateMfa() => throw UnimplementedError();
  @override
  Future<void> enableMfa(String totp) => throw UnimplementedError();
  @override
  Future<void> disableMfa(String code) => throw UnimplementedError();
  @override
  Future<AuthResponse> completeMfaSignIn(
          {required String otp, required String ticket}) =>
      throw UnimplementedError();
  @override
  Future<void> completeOAuthProviderSignIn(Uri redirectUrl) =>
      throw UnimplementedError();
  @override
  Future<AuthResponse> signInWithPat(String pat) => throw UnimplementedError();
  @override
  Future<User> fetchUser() => throw UnimplementedError();
  @override
  Future<bool> verifyToken(String accessToken) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> signInWithWebAuthn() =>
      throw UnimplementedError();
  @override
  Future<AuthResponse> verifyWebAuthnSignIn(
          Map<String, dynamic> assertionResponse) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> signUpWithWebAuthn({String? email}) =>
      throw UnimplementedError();
  @override
  Future<AuthResponse> verifyWebAuthnSignUp(
          Map<String, dynamic> attestationResponse) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> addWebAuthnCredential() =>
      throw UnimplementedError();
  @override
  Future<void> verifyAddWebAuthnCredential(
          Map<String, dynamic> attestationResponse) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> elevateWithWebAuthn() =>
      throw UnimplementedError();
  @override
  Future<AuthResponse> verifyWebAuthnElevation(
          Map<String, dynamic> assertionResponse) =>
      throw UnimplementedError();
  @override
  Future<void> setSession(Session session) => throw UnimplementedError();
  @override
  Future<void> clearSession() => throw UnimplementedError();
}

User makeUser({String email = 'test@example.com'}) => User(
      id: 'u1',
      displayName: 'Test',
      locale: 'en',
      createdAt: DateTime.utc(2024),
      isAnonymous: false,
      defaultRole: 'user',
      roles: const ['user'],
      emailVerified: true,
      phoneNumber: '',
      phoneNumberVerified: false,
      email: email,
    );

// A valid JWT is required because UserSession.session= calls JwtDecoder.decode.
const _validJwt =
    'eyJhbGciOiJIUzI1NiJ9'
    '.eyJodHRwczovL2hhc3VyYS5pby9qd3QvY2xhaW1zIjp7IngtaGFzdXJhLWFsbG93ZWQtcm9sZXMiOlsidXNlciJdLCJ4LWhhc3VyYS1kZWZhdWx0LXJvbGUiOiJ1c2VyIiwieC1oYXN1cmEtdXNlci1pZCI6InUxIn0sInN1YiI6InUxIiwiaWF0IjoxNjAwMDAwMDAwLCJleHAiOjk5OTk5OTk5OTl9'
    '.signature';

Session makeSession() => Session(
      accessToken: _validJwt,
      accessTokenExpiresIn: const Duration(seconds: 900),
      refreshToken: 'ref',
      user: makeUser(),
    );
