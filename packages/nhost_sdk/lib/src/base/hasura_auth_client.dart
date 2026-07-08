import 'package:meta/meta.dart';

import '../api/auth_api_types.dart';
import '../foundation/types.dart';

abstract class HasuraAuthClient {
  User? get currentUser;

  AuthenticationState get authenticationState;

  String? get accessToken;

  String? getClaim(String jwtClaim);

  void close();

  UnsubscribeDelegate addTokenChangedCallback(TokenChangedCallback callback);

  UnsubscribeDelegate addAuthStateChangedCallback(
      AuthStateChangedCallback callback);

  UnsubscribeDelegate addSessionRefreshFailedCallback(
      SessionRefreshFailedCallback callback);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? locale,
    String? defaultRole,
    Map<String, Object?>? metadata,
    List<String>? roles,
    String? displayName,
    String? redirectTo,
  });

  Future<AuthResponse> signInEmailPassword({
    required String email,
    required String password,
  });

  Future<AuthResponse> signInIdToken(
      {required String provider, required String idToken, String? nonce});

  Future<void> linkIdToken(
      {required String provider, required String idToken, String? nonce});

  Future<void> signInWithEmailPasswordless({
    required String email,
    String? locale,
    String? defaultRole,
    Map<String, Object?>? metadata,
    List<String>? roles,
    String? displayName,
    String? redirectTo,
  });

  Future<void> signInAnonymous(
    String? displayName,
    String? locale,
    Map<String, dynamic>? metadata,
  );

  Future<void> deanonymizeUser(
    DeanonymizeOptions options,
  );

  Future<void> signInWithSmsPasswordless({
    required String phoneNumber,
    String? locale,
    String? defaultRole,
    Map<String, Object?>? metadata,
    List<String>? roles,
    String? displayName,
    String? redirectTo,
  });

  Future<AuthResponse> completeSmsPasswordlessSignIn(
    String phoneNumber,
    String otp,
  );

  Future<void> signInEmailOTP({
    required String email,
    String? locale,
    String? defaultRole,
    Map<String, Object?>? metadata,
    List<String>? roles,
    String? displayName,
    String? redirectTo,
  });

  Future<AuthResponse> verifyEmailOTP(
      {required String email, required String otp});

  Future<AuthResponse> signInWithStoredCredentials();
  Future<AuthResponse> signInWithRefreshToken(String refreshToken);

  Future<AuthResponse> signOut({
    bool all = false,
  });

  Future<void> sendVerificationEmail({
    required String email,
    String? redirectTo,
  });

  Future<void> changeEmail(String newEmail);

  Future<void> changePassword({
    required String newPassword,
    String? ticket,
  });

  Future<void> resetPassword({
    required String email,
    String? redirectTo,
  });

  Future<MultiFactorAuthResponse> generateMfa();

  Future<void> enableMfa(String totp);
  Future<void> disableMfa(String code);

  Future<AuthResponse> completeMfaSignIn({
    required String otp,
    required String ticket,
  });

  Future<void> completeOAuthProviderSignIn(Uri redirectUrl);

  /// Signs in using a Personal Access Token (PAT).
  ///
  /// PATs are long-lived tokens suited for CI/CD, scripts, and server-to-server
  /// calls. Create a PAT in the Nhost dashboard → Account settings → PATs.
  Future<AuthResponse> signInWithPat(String pat);

  /// Fetches the current user's profile directly from the server.
  ///
  /// Useful for forcing a user-data refresh without a full token cycle.
  Future<User> fetchUser();

  /// Verifies whether [accessToken] is still valid on the server.
  ///
  /// Returns `true` if the token is valid, `false` otherwise.
  Future<bool> verifyToken(String accessToken);

  // ---------------------------------------------------------------------------
  // WebAuthn — platform-dependent
  // The methods below require a FIDO2/WebAuthn platform integration.
  // On Flutter, pair with a native plugin (e.g. flutter_web_auth_2).
  // Call the server endpoints, but the challenge creation/assertion must be
  // handled by the platform layer before calling these.
  // ---------------------------------------------------------------------------

  /// Initiates WebAuthn sign-in. Returns the server challenge that the
  /// platform layer must sign before calling [verifyWebAuthnSignIn].
  Future<Map<String, dynamic>> signInWithWebAuthn();

  /// Completes WebAuthn sign-in with the [assertionResponse] produced by the
  /// platform authenticator.
  Future<AuthResponse> verifyWebAuthnSignIn(
    Map<String, dynamic> assertionResponse,
  );

  /// Initiates WebAuthn sign-up. Returns the server challenge that the
  /// platform layer must use to create a new credential.
  Future<Map<String, dynamic>> signUpWithWebAuthn({String? email});

  /// Completes WebAuthn sign-up with the [attestationResponse] produced by
  /// the platform authenticator.
  Future<AuthResponse> verifyWebAuthnSignUp(
    Map<String, dynamic> attestationResponse,
  );

  /// Initiates adding a new WebAuthn credential to an existing account.
  Future<Map<String, dynamic>> addWebAuthnCredential();

  /// Completes adding a WebAuthn credential with the [attestationResponse].
  Future<void> verifyAddWebAuthnCredential(
    Map<String, dynamic> attestationResponse,
  );

  /// Initiates a session-elevation flow via WebAuthn.
  Future<Map<String, dynamic>> elevateWithWebAuthn();

  /// Completes session elevation with the [assertionResponse].
  Future<AuthResponse> verifyWebAuthnElevation(
    Map<String, dynamic> assertionResponse,
  );

  @visibleForTesting
  Future<void> setSession(Session session);

  @visibleForTesting
  Future<void> clearSession();
}

enum DeanonymizeSignInMethod {
  emailPassword,
  passwordless;

  String get serialized {
    switch (this) {
      case DeanonymizeSignInMethod.emailPassword:
        return 'email-password';
      case DeanonymizeSignInMethod.passwordless:
        return 'passwordless';
    }
  }
}

@immutable
class DeanonymizeOptions {
  DeanonymizeOptions({
    required this.signInMethod,
    required this.email,
    this.password,
    this.allowedRoles,
    this.defaultRole,
    this.displayName,
    this.locale,
    this.metadata,
    this.redirectTo,
  });

  final DeanonymizeSignInMethod signInMethod;
  final String email;
  final String? password;
  final Iterable<String>? allowedRoles;
  final String? defaultRole;
  final String? displayName;
  final String? locale;
  final Map<String, dynamic>? metadata;
  final Uri? redirectTo;

  Map<String, dynamic> toJson() {
    if (password != null && (password!.length < 3 || password!.length > 50)) {
      throw ArgumentError.value(
          password, 'password', 'Must be between 3 and 50 characters');
    }

    if (locale != null && locale!.length != 2) {
      throw ArgumentError.value(
          locale, 'locale', 'Must be a 2-character locale');
    }

    if (displayName != null && displayName!.length > 32) {
      throw ArgumentError.value(
          displayName, 'displayName', 'Must be at most 32 characters');
    }

    return {
      'signInMethod': signInMethod.serialized,
      'email': email,
      if (password != null) 'password': password,
      'options': {
        if (allowedRoles != null) 'allowedRoles': allowedRoles,
        if (defaultRole != null) 'defaultRole': defaultRole,
        if (displayName != null) 'displayName': displayName,
        if (locale != null) 'locale': locale,
        if (metadata != null) 'metadata': metadata,
        if (redirectTo != null) 'redirectTo': redirectTo.toString(),
      }
    };
  }
}
