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

  @visibleForTesting
  Future<void> setSession(Session session);

  @visibleForTesting
  Future<void> clearSession();
}
